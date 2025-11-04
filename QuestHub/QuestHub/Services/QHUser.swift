//
//  QHUser.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/4/25.
//

import Foundation
import Combine
import FirebaseAuth

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

    enum AuthError: LocalizedError, Equatable {
        case invalidEmail
        case shortPassword
        case userNotFound
        case emailAlreadyInUse
        case wrongPassword
        case network
        case unknown

        var errorDescription: String? {
            switch self {
            case .invalidEmail: return "The email address appears to be invalid."
            case .shortPassword: return "Password needs to be at least 6 characters long."
            case .userNotFound: return "No user found with those credentials."
            case .emailAlreadyInUse: return "An account with this email already exists."
            case .wrongPassword: return "The password is incorrect."
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

            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            let fbUser = result.user
            let user = QHUser(
                id: fbUser.uid,
                email: fbUser.email ?? email,
                displayName: fbUser.displayName,
                createdAt: Date() // Firebase provides metadata, but we keep a local date for simplicity
            )

            // No local persistence; rely on Firebase session. Optionally mirror for offline UI.
            persistSession(user: user)

            currentUser = user
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

            let fbUser = result.user
            let user = QHUser(
                id: fbUser.uid,
                email: fbUser.email ?? email,
                displayName: fbUser.displayName ?? displayName,
                createdAt: Date()
            )

            persistSession(user: user)
            currentUser = user
            return true
        } catch {
            lastError = mapFirebaseError(error)
            return false
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
        currentUser = nil
        clearPersistedSession()
    }

    /// Attempts to restore a previously persisted session (if any).
    func restoreSessionIfAvailable() {
        if let fbUser = Auth.auth().currentUser {
            let user = QHUser(
                id: fbUser.uid,
                email: fbUser.email ?? "",
                displayName: fbUser.displayName,
                createdAt: Date()
            )
            currentUser = user
            persistSession(user: user) // keep local mirror for UI convenience
            return
        }
        if let data = UserDefaults.standard.data(forKey: Self.sessionKey),
           let user = try? JSONDecoder().decode(QHUser.self, from: data) {
            currentUser = user
        }
    }

    // MARK: - Private helpers

    private func mapFirebaseError(_ error: Error) -> Error {
        let nsError = error as NSError
        if nsError.domain == AuthErrorDomain, let code = AuthErrorCode(rawValue: nsError.code) {
            switch code {
            case .invalidEmail: return AuthError.invalidEmail
            case .userNotFound: return AuthError.userNotFound
            case .emailAlreadyInUse: return AuthError.emailAlreadyInUse
            case .wrongPassword: return AuthError.wrongPassword
            case .networkError: return AuthError.network
            default: return AuthError.unknown
            }
        }
        return error
    }

    private func validate(email: String, password: String) throws {
        guard email.contains("@"), email.contains("."), email.count >= 5 else {
            throw AuthError.invalidEmail
        }
        guard password.count >= 6 else {
            throw AuthError.shortPassword
        }
    }

    private func persistSession(user: QHUser) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: Self.sessionKey)
        }
    }

    private func clearPersistedSession() {
        UserDefaults.standard.removeObject(forKey: Self.sessionKey)
    }

    private static let sessionKey = "QHUserSession"
}

