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
    let auth: QHAuth
    @Published var foundQuest: Quest?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var inputPassword: String = ""

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
    
    func requiresPassword() -> Bool {
        return !(foundQuest?.password ?? "").isEmpty
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
        if requiresPassword() && inputPassword.isEmpty {
            errorMessage = "This quest requires a password."
            return
        }
        
        if let password = quest.password, requiresPassword(), !inputPassword.elementsEqual(password) {
            print("Passwords must match")
            return
        }

        // Proceed to join
        print("Joining quest: \(quest.questCode)")
        // Implement the actual join logic here (network/database call)
    }
}

