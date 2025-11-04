//
//  HomeView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/3/25.
//

import SwiftUI
import CoreData

struct HomeView: View {
    // Persist a flag indicating whether onboarding has been shown
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @Environment(\.managedObjectContext) private var viewContext

    @State private var showOnboarding: Bool = false

    var body: some View {
        // Your main home content placeholder
        VStack(spacing: 16) {
            Text("Home")
                .font(.largeTitle).bold()
            Text("Welcome to QuestHub")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        // Present onboarding full-screen only on first launch
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                // Mark onboarding complete and dismiss
                hasCompletedOnboarding = true
                showOnboarding = false
            }
        }
        .onAppear {
            // Show onboarding if not completed yet
            if !hasCompletedOnboarding {
                // Defer to next runloop to avoid "Modifying state during view update" warnings
                DispatchQueue.main.async {
                    showOnboarding = true
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
