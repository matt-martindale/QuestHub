//
//  PlayQuestViewModel.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/13/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class PlayQuestViewModel: ObservableObject {
    let auth: QHAuth
    @Published var quest: Quest
    @Published var inputPassword: String = ""
    @Published var alertMessage: AlertMessage?
    
    init(auth: QHAuth, quest: Quest) {
        self.auth = auth
        self.quest = quest
    }
    
    var headerImageURL: URL? {
        // Prefer embedded image data by generating a data URL if available
        if let data = quest.imageData, !data.isEmpty {
            let base64 = data.base64EncodedString()
            // Assume JPEG by default; adjust if you store MIME type elsewhere
            return URL(string: "data:image/jpeg;base64,\(base64)")
        }
        if let urlString = quest.imageURL, let url = URL(string: urlString) {
            return url
        }
        return nil
    }
    
    var questDescription: String {
        if let questDescription = quest.description, !questDescription.isEmpty {
            return questDescription
        }
        return "Get ready to explore, solve challenges, and progress through this quest. Complete tasks, earn points, and uncover surprises along the way!"
    }
    
    // MARK: Helper Methods
    func requiresPassword() -> Bool {
        return !(quest.password ?? "").isEmpty
    }
    
    // MARK: Actions
    func joinQuest() {
        guard let questID = quest.id,
        let questCode = quest.questCode else { return }
        alertMessage = nil
        
        if auth.currentUser == nil {
            self.alertMessage = AlertMessage(text: "Please sign in or create an account to join a quest.")
            return
        }

        // Password-protected quest
        if requiresPassword() && inputPassword.isEmpty {
            alertMessage = AlertMessage(text: "This quest requires a password.")
            return
        }
        
        if let password = quest.password, requiresPassword(), !inputPassword.elementsEqual(password) {
            alertMessage = AlertMessage(text: "Passwords must match")
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
