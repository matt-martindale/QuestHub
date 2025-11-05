//
//  HomeView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/3/25.
//

import SwiftUI
import CoreData
import Foundation

struct HomeView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var auth: QHAuth

    @State private var showOnboarding: Bool = false

    var body: some View {
        NavigationStack {
            // Your main home content placeholder
            VStack(spacing: 8) {
                Text(UIStrings.welcomeToQuestHub)
                    .font(.largeTitle).bold()

                VStack(spacing: 12) {
                    NavigationLink(destination: destinationForOrganizer()) {
                        Text(UIStrings.joinAsOrganizer)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemBackground))
                            .foregroundColor(.primary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.qhPrimaryBlue, lineWidth: 4)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    NavigationLink(destination: SearchQuestView()) {
                        Text(UIStrings.joinAsPlayer)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.qhPrimaryBlue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(.top, 24)
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .toolbar {
                if let user = auth.currentUser {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button(role: .destructive) {
                                auth.signOut()
                            } label: {
                                Label(UIStrings.signOut, systemImage: "rectangle.portrait.and.arrow.right")
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
                }
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                // Mark onboarding complete and dismiss
                hasCompletedOnboarding = true
                showOnboarding = false
            }
        }
        .onAppear {
            if !hasCompletedOnboarding {
                // Defer to next runloop to avoid "Modifying state during view update" warnings
                DispatchQueue.main.async {
                    showOnboarding = true
                }
            }
        }
    }

    @ViewBuilder
    private func destinationForOrganizer() -> some View {
        OrganizerDestination()
    }

    private struct OrganizerDestination: View {
        @Environment(\.dismiss) private var dismiss
        var body: some View {
            OrganizerHubView()
                .requiresSignIn {
                    // Pop back if the user cancels sign-in
                    dismiss()
                }
        }
    }

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
    let auth = QHAuth()
    // Uncomment to preview the signed-in state
    // Task { @MainActor in auth.restoreSessionIfAvailable() }
    return HomeView()
        .environmentObject(auth)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
