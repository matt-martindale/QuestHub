//
//  QHUser.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/4/25.
//

import Foundation
import Combine

/// A simple user model and sign-in manager.
///
/// This file provides:
/// - `QHUser`: a lightweight user value type
/// - `QHAuth`: a simple sign-in/sign-out manager using Swift Concurrency
///
/// NOTE: This is a placeholder auth flow. Replace the `validateCredentials`
/// and persistence logic with your real backend (e.g., your API, Firebase, etc.).

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
        case invalidPassword
        case userNotFound
        case network
        case unknown

        var errorDescription: String? {
            switch self {
            case .invalidEmail: return "The email address appears to be invalid."
            case .invalidPassword: return "The password is incorrect."
            case .userNotFound: return "No user found with those credentials."
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

            // Simulate a network call
            let user = try await fetchUserForCredentials(email: email, password: password)

            // Persist if desired (Keychain, file, etc.)
            persistSession(user: user)

            currentUser = user
            return true
        } catch {
            lastError = error
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

            // Simulate a network call to create the user
            let newUser = try await createUser(email: email, password: password, displayName: displayName)

            // Persist if desired
            persistSession(user: newUser)

            currentUser = newUser
            return true
        } catch {
            lastError = error
            return false
        }
    }

    /// Signs the current user out and clears any persisted session.
    func signOut() {
        currentUser = nil
        clearPersistedSession()
    }

    /// Attempts to restore a previously persisted session (if any).
    func restoreSessionIfAvailable() {
        if let data = UserDefaults.standard.data(forKey: Self.sessionKey),
           let user = try? JSONDecoder().decode(QHUser.self, from: data) {
            currentUser = user
        }
    }

    // MARK: - Private helpers

    private func validate(email: String, password: String) throws {
        guard email.contains("@"), email.contains("."), email.count >= 5 else {
            throw AuthError.invalidEmail
        }
        guard password.count >= 6 else {
            throw AuthError.invalidPassword
        }
    }

    private func fetchUserForCredentials(email: String, password: String) async throws -> QHUser {
        // Simulate latency
        try await Task.sleep(nanoseconds: 500_000_000)

        // Placeholder logic: accept any email/password that meets validation
        // In a real app, call your backend and verify credentials.
        // You might throw `AuthError.userNotFound` or `AuthError.network` as appropriate.
        return QHUser(email: email, displayName: email.split(separator: "@").first.map(String.init))
    }

    private func createUser(email: String, password: String, displayName: String?) async throws -> QHUser {
        // Simulate latency
        try await Task.sleep(nanoseconds: 600_000_000)

        // Placeholder logic: create and return a new user
        return QHUser(email: email, displayName: displayName)
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

