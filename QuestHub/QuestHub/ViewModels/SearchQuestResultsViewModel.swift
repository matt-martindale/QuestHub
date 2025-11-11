//
//  SearchQuestResultsViewModel.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/11/25.
//

import Foundation
import Combine

@MainActor
final class SearchQuestResultsViewModel: ObservableObject {
    // Dependencies
    let auth: QHAuth

    // Input quest from search; expose as optional to allow "empty" state in the view
    @Published var foundQuest: Quest?

    // UI state
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // Any listeners/cancellables can be tracked here if needed
    private var cancellables = Set<AnyCancellable>()

    init(auth: QHAuth, quest: Quest) {
        self.auth = auth
        self.auth.signOutIfAnonymous()
        self.foundQuest = quest
    }

    // MARK: - User Quest Listening
    func startListeningForUserQuests(for userID: String) {
        // Stub: Hook up to your data layer to listen for changes affecting the user's quests.
        // Provided to satisfy view calls and can be implemented later.
        // Example: subscribe to a publisher and update state.
    }

    func stopListening() {
        // Cancel any active subscriptions or listeners
        cancellables.removeAll()
    }

    // MARK: - Actions
    func joinQuest() {
        guard let quest = foundQuest else { return }

        // Require sign-in if needed
        if quest.requireSignIn == true, auth.currentUser == nil {
            // You can surface this via errorMessage if desired
            print("Sign in required, please sign-in")
            errorMessage = "Sign in required to join this quest."
            return
        }

        // Password-protected quest
        if let password = quest.password, !password.isEmpty {
            print("Please enter password")
            // In a real flow you'd prompt for password; for now, just message.
            errorMessage = "This quest requires a password."
            return
        }

        // Proceed to join
        print("Joining quest: \(quest.questCode)")
        // Implement the actual join logic here (network/database call)
    }
}

