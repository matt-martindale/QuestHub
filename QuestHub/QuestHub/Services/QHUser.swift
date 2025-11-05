//
//  QHUser.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/4/25.
//

import Foundation
import Combine
import FirebaseAuth
import AuthenticationServices

struct QHUser: Codable, Equatable, Identifiable {
    let id: String
    var email: String
    var displayName: String?
    var createdAt: Date

    init(id: String = UUID().uuidString, email: String, displayName: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.createdAt = createdAt
    }
}

@MainActor
final class QHAuth: ObservableObject {
    @Published private(set) var currentUser: QHUser?
    @Published private(set) var isSigningIn: Bool = false
    @Published private(set) var lastError: Error?
    
    private var authListenerHandle: AuthStateDidChangeListenerHandle?
    
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

            // Update display name if provided
            if let displayName, !displayName.isEmpty {
                let changeReq = result.user.createProfileChangeRequest()
                changeReq.displayName = displayName
                try await changeReq.commitChanges()
            }

            // Listener will update currentUser when Firebase signs up/signs in
            return true
        } catch {
            lastError = mapFirebaseError(error)
            return false
        }
    }
    
    func handleAppleCredential(_ credential: ASAuthorizationAppleIDCredential, nonce: String) async throws {
        try await AuthService.shared.signInWithApple(credential: credential, nonce: nonce)
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
                let user = QHUser(
                    id: fbUser.uid,
                    email: fbUser.email ?? "",
                    displayName: fbUser.displayName,
                    createdAt: Date()
                )
                self.currentUser = user
            } else {
                self.currentUser = nil
            }
        }
    }
}
