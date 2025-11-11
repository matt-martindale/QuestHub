//
//  QHAuth.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/5/25.
//

import Foundation
import Combine
import FirebaseAuth
import AuthenticationServices
import FirebaseFirestore

@MainActor
final class QHAuth: ObservableObject {
    @Published private(set) var currentUser: QHUser?
    @Published private(set) var isSigningIn: Bool = false
    @Published private(set) var isLoadingCreatedQuests: Bool = false
    @Published private(set) var createdQuests: [Quest] = []
    @Published private(set) var lastError: Error?
    
    private var authListenerHandle: AuthStateDidChangeListenerHandle?
    let firestore = FirestoreService()
    
    init() {
        startAuthStateListener()
    }
    
    deinit {
        if let handle = authListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    enum AuthError: LocalizedError, Equatable {
        case invalidEmail
        case shortPassword
        case userNotFound
        case emailAlreadyInUse
        case wrongPassword
        case invalidCredentials
        case network
        case unknown

        var errorDescription: String? {
            switch self {
            case .invalidEmail: return "The email address appears to be invalid."
            case .shortPassword: return "Password needs to be at least 6 characters long."
            case .userNotFound: return "No user found with those credentials."
            case .emailAlreadyInUse: return "An account with this email already exists."
            case .wrongPassword: return "The password is incorrect."
            case .invalidCredentials: return "Invalid login credentials"
            case .network: return "A network error occurred. Please try again."
            case .unknown: return "An unknown error occurred."
            }
        }
    }

    // MARK: - Public API

    /// Attempts to sign in with email and password.
    /// Replace the internals with your backend call.
    func signIn(email: String, password: String) async -> Bool {
        isSigningIn = true
        lastError = nil
        defer { isSigningIn = false }

        do {
            try validate(email: email, password: password)

            _ = try await Auth.auth().signIn(withEmail: email, password: password)
            if let fbUser = Auth.auth().currentUser {
                // Build a local user first
                var user = QHUser(
                    id: fbUser.uid,
                    email: fbUser.email ?? "",
                    displayName: fbUser.displayName,
                    createdAt: Date()
                )
                self.currentUser = user
            }
            // Listener will update currentUser when Firebase signs in
            return true
        } catch {
            lastError = mapFirebaseError(error)
            return false
        }
    }

    /// Creates a new account and signs the user in.
    func signUp(email: String, password: String, displayName: String?) async -> Bool {
        isSigningIn = true
        lastError = nil
        defer { isSigningIn = false }

        do {
            try validate(email: email, password: password)

            let result = try await Auth.auth().createUser(withEmail: email, password: password)

            // If a display name was provided, set it and commit the change
            if let displayName, !displayName.isEmpty {
                let changeReq = result.user.createProfileChangeRequest()
                changeReq.displayName = displayName
                try await changeReq.commitChanges()
            }

            // Ensure the in-memory user reflects the latest profile changes
            try await result.user.reload()

            // Update local currentUser immediately so UI reflects the name right away
            let fbUser = result.user
            var user = QHUser(
                id: fbUser.uid,
                email: fbUser.email ?? "",
                displayName: fbUser.displayName,
                createdAt: Date()
            )

            self.currentUser = user

            // Listener will also keep currentUser in sync going forward
            return true
        } catch {
            lastError = mapFirebaseError(error)
            return false
        }
    }
    
    /// Fetches quests created by the currently signed-in user from the root "quests" collection.
    /// Returns an empty array if no user is signed in or if an error occurs.
    func fetchCreatedQuests() async -> [Quest] {
        isLoadingCreatedQuests = true
        lastError = nil
        defer { isLoadingCreatedQuests = false }

        guard let userId = Auth.auth().currentUser?.uid else {
            self.createdQuests = []
            return []
        }
        do {
            let snapshot = try await Firestore.firestore()
                .collection("quests")
                .whereField("creatorID", isEqualTo: userId)
                .order(by: "createdAt", descending: true)
                .getDocuments()

            var latest: [Quest] = []
            for document in snapshot.documents {
                if let quest = try? document.data(as: Quest.self) {
                    latest.append(quest)
                } else {
                    continue
                }
            }
            self.createdQuests = latest
            return latest
        } catch {
            self.lastError = error
            self.createdQuests = []
            return []
        }
    }

    func handleAppleCredential(_ credential: ASAuthorizationAppleIDCredential, nonce: String) async throws {
        try await AuthService.shared.handleAppleCredential(credential, nonce: nonce)
        
        if let nameComponents = credential.fullName {
            let formatter = PersonNameComponentsFormatter()
            let formattedName = formatter.string(from: nameComponents).trimmingCharacters(in: .whitespacesAndNewlines)
            if !formattedName.isEmpty {
                do {
                    try await AuthService.shared.updateDisplayName(formattedName)
                } catch {
                    self.lastError = error
                }
                
                // Update local user so UI reflects the name immediately
                if var user = self.currentUser {
                    user.displayName = formattedName
                    self.currentUser = user
                }
            }
        }
    }

    /// Signs the current user out and clears any persisted session.
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            // Surface sign-out errors but still clear local state
            lastError = error
        }
        // Listener will clear currentUser when sign out completes
    }

    // MARK: - Private helpers

    private func mapFirebaseError(_ error: Error) -> Error {
        let nsError = error as NSError
        // If it's a Firebase Auth error, return it as-is to preserve localization
        if nsError.domain == AuthErrorDomain, AuthErrorCode(rawValue: nsError.code) != nil {
            return nsError
        }
        // Otherwise, fall back to your own categorization if you want
        return AuthError.unknown
    }

    private func validate(email: String, password: String) throws {
        guard email.contains("@"), email.contains("."), email.count >= 5 else {
            throw AuthError.invalidEmail
        }
        guard password.count >= 6 else {
            throw AuthError.shortPassword
        }
    }
    
    private func startAuthStateListener() {
        authListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, fbUser in
            guard let self = self else { return }
            if let fbUser {
                Task { [weak self] in
                    guard let self = self else { return }
                    var user = QHUser(
                        id: fbUser.uid,
                        email: fbUser.email ?? "",
                        displayName: fbUser.displayName,
                        createdAt: Date()
                    )
                    self.currentUser = user
                }
            } else {
                self.currentUser = nil
            }
        }
    }
}

