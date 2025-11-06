//
//  SignedInUserMenu.swift
//  QuestHub
//
//  Created by Assistant on 11/5/25.
//

import SwiftUI
import Foundation

struct SignedInUserMenu: View {
    let user: QHUser
    var allowSignOut: Bool = true
    var signOut: (() -> Void)?

    init(user: QHUser, allowSignOut: Bool = true, signOut: (() -> Void)? = nil) {
        self.user = user
        self.allowSignOut = allowSignOut
        self.signOut = signOut
    }

    public var body: some View {
        Menu {
            if allowSignOut {
                Button(role: .destructive) {
                    signOut?()
                } label: {
                    Label(UIStrings.signOut, systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        } label: {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .overlay(
                            Circle().stroke(Color.qhPrimaryBlue, lineWidth: 1)
                        )
                    Text(initials(from: user))
                        .font(.caption.bold())
                        .foregroundColor(.primary)
                }
                .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 0) {
                    Text(UIStrings.signedInAs)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(displayName(for: user))
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 6)
        }
    }

    // MARK: - Helpers
    private func displayName(for user: QHUser) -> String {
        if let name = user.displayName, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return name
        }
        // Fallback to email if no display name
        return user.email
    }

    private func initials(from user: QHUser) -> String {
        let name = (user.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? user.email
        let parts = name
            .split(whereSeparator: { $0 == " " || $0 == "_" || $0 == "-" || $0 == "." })
        let first = parts.first?.first
        let second = parts.dropFirst().first?.first
        let initials = String([first, second].compactMap { $0 }).uppercased()
        if initials.isEmpty, let c = name.first {
            return String(c).uppercased()
        }
        return initials
    }
}

#Preview {
    VStack(spacing: 16) {
        let user = QHUser(id: "preview", email: "preview@example.com", displayName: "Preview User")
        SignedInUserMenu(user: user, allowSignOut: true) {
            // sign out action
        }
        SignedInUserMenu(user: user, allowSignOut: false)
    }
    .padding()
}
