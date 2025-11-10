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
                Spacer()
                Image(systemName: "flag.2.crossed.circle")
                    .font(.system(size: 80))
                
                Text(UIStrings.welcomeToQuestHub)
                    .font(.largeTitle).bold()
                
                Spacer()
                    .frame(height: 20)

                VStack(spacing: 12) {
                    NavigationLink(destination: destinationForOrganizer()) {
                        Text(UIStrings.joinAsOrganizer)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
//                            .background(Color.qhPrimaryBlue)
//                            .foregroundColor(.white)
                            .background(Color(.systemBackground))
                            .foregroundColor(.primary)
                            .overlay(
                                Capsule()
                                    .stroke(Color.qhPrimaryBlue, lineWidth: 4)
                            )
                            .clipShape(.capsule)
                    }

                    NavigationLink(destination: PlayerHubView()) {
                        Text(UIStrings.joinAsPlayer)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
//                            .background(Color.qhPrimaryBlue)
//                            .foregroundColor(.white)
                            .background(Color(.systemBackground))
                            .foregroundColor(.primary)
                            .overlay(
                                Capsule()
                                    .stroke(Color.qhPrimaryBlue, lineWidth: 4)
                            )
                            .clipShape(.capsule)
                    }
                }
                .padding(.top, 24)
                .padding(.horizontal)
                
                Spacer()
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .toolbar {
                if let user = auth.currentUser {
                    ToolbarItem(placement: .topBarTrailing) {
                        SignedInUserMenu(user: user) {
                            auth.signOut()
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
        return user.email ?? "anonymous"
    }

    private func initials(from user: QHUser) -> String {
        let name = (user.displayName?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 } ?? user.email
        let parts = name?
            .split(whereSeparator: { $0 == " " || $0 == "_" || $0 == "-" || $0 == "." })
        let first = parts?.first?.first
        let second = parts?.dropFirst().first?.first
        let initials = String([first, second].compactMap { $0 }).uppercased()
        if initials.isEmpty, let c = name?.first {
            return String(c).uppercased()
        }
        return initials
    }
}

#Preview {
    let auth = QHAuth()
    // Optionally simulate a signed-in state for previews, e.g.:
    // auth.currentUser = QHUser(id: "preview", email: "preview@example.com", displayName: "Preview User")
    HomeView()
        .environmentObject(auth)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
