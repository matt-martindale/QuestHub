//
//  SearchQuestResultsViewModel.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/11/25.
//

import Foundation
import Combine

struct AlertMessage: Identifiable { let id = UUID(); let text: String }

@MainActor
final class SearchQuestResultsViewModel: ObservableObject {
    let auth: QHAuth
    @Published var foundQuest: Quest?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var alertMessage: AlertMessage?
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
        guard let quest = foundQuest,
        let questID = quest.id,
        let questCode = quest.questCode else { return }
        errorMessage = nil
        
        if auth.currentUser == nil {
            self.alertMessage = AlertMessage(text: "Please sign in or create an account to join a quest.")
            return
        }

        // Password-protected quest
        if requiresPassword() && inputPassword.isEmpty {
            errorMessage = "This quest requires a password."
            return
        }
        
        if let password = quest.password, requiresPassword(), !inputPassword.elementsEqual(password) {
            errorMessage = "Passwords must match"
            return
        }
        
        // Join Quest after passing validations
        QuestService.shared.joinQuest(questId: questID, questCode: questCode, userId: auth.currentUser?.id, userDisplayName: auth.currentUser?.displayName ?? auth.currentUser?.email ?? "anonymous", maxPlayersEnforced: true) { result in
            switch result {
            case .success():
                print("Joined quest \(questCode)")
            case .failure(let error):
                self.alertMessage = AlertMessage(text: error.localizedDescription)
            }
        }
    }
}

