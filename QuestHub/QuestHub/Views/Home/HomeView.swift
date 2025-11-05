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
                Text("Welcome to QuestHub")
                    .font(.largeTitle).bold()

                VStack(spacing: 12) {
                    NavigationLink(destination: destinationForOrganizer()) {
                        Text("Join as Organizer")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .foregroundColor(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    NavigationLink(destination: SearchQuestView()) {
                        Text("Join as Player")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(.top, 24)
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
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
        if let _ = auth.currentUser {
            OrganizerHubView()
        } else {
            SignInView()
                .environmentObject(auth)
        }
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

struct SignedInOrganizerHomeView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Organizer Home").font(.largeTitle).bold()
            Text("You're signed in as organizer.")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
