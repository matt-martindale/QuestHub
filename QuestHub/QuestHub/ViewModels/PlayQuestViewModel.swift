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
    @ObservedObject var auth: QHAuth
    @Published var isJoined: Bool = false
    @Published var quest: Quest
    @Published var inputPassword: String = ""
    @Published var alertMessage: AlertMessage?
    @Published var showingPasswordSheet: Bool = false
    @Published var passwordError: String? = nil
    @Published var isJoining: Bool = false
    @Published var showingLeaveConfirmation: Bool = false
    
    init(auth: QHAuth, quest: Quest) {
        self.auth = auth
        self.quest = quest
        // Check if the current user has already joined this quest
        if let uid = auth.currentUser?.id, let qid = quest.id, !uid.isEmpty, !qid.isEmpty {
            Task { [weak self] in
                guard let self = self else { return }
                do {
                    let joined = try await QuestService.shared.hasJoinedQuest(userId: uid, questId: qid)
                    self.isJoined = joined
                } catch {
                    // Non-fatal: if this fails, we simply leave isJoined as false
                    print("hasJoinedQuest check failed: \(error.localizedDescription)")
                }
            }
        }
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
    
    // MARK: Join Flow Orchestration
    /// Call from the View when the user taps Join. This defers to a sheet if a password is required and not yet provided.
    func beginJoinFlow() {
        alertMessage = nil
        if auth.currentUser == nil {
            self.alertMessage = AlertMessage(text: "Please sign in or create an account to join a quest.")
            isJoining = false
            return
        }
        if requiresPassword() && inputPassword.isEmpty {
            showingPasswordSheet = true
            return
        }
        joinQuest()
    }
    
    func confirmPasswordAndJoin() {
        let requiredPassword = quest.password ?? ""
        if inputPassword == requiredPassword {
            passwordError = nil
            joinQuest()
            showingPasswordSheet = false
        } else {
            passwordError = "Incorrect password. Please try again."
        }
    }
    
    // MARK: Actions
    
    func joinQuest() {
        guard let questID = quest.id,
        let questCode = quest.questCode else { return }
        alertMessage = nil
        isJoining = true
        
        if auth.currentUser == nil {
            self.alertMessage = AlertMessage(text: "Please sign in or create an account to join a quest.")
            isJoining = false
            return
        }
        
        // Join Quest after passing validations
        QuestService.shared.joinQuest(questId: questID, questCode: questCode, userId: auth.currentUser?.id, userDisplayName: auth.currentUser?.displayName ?? auth.currentUser?.email ?? "anonymous", maxPlayersEnforced: true) { result in
            switch result {
            case .success():
                self.isJoining = false
                print("Joined quest \(questCode)")
                self.isJoined = true
                if let current = self.quest.playersCount {
                    self.quest.playersCount = current + 1
                } else {
                    self.quest.playersCount = 1
                }
            case .failure(let error):
                self.isJoining = false
                self.alertMessage = AlertMessage(text: error.localizedDescription)
            }
        }
    }
    
    func leaveQuest() {
        print("Leaving quest")
        guard let questID = quest.id,
        let userId = auth.currentUser?.id else { return }
        QuestService.shared.leaveQuest(questId: questID, userId: userId) { [weak self] result in
            switch result {
            case .success():
                print("Successfully left quest")
                self?.isJoined = false
                if let current = self?.quest.playersCount {
                    self?.quest.playersCount = max(current - 1, 0)
                } else {
                    self?.quest.playersCount = 0
                }
            case .failure(let error):
                self?.alertMessage = AlertMessage(text: error.localizedDescription)
            }
        }
    }
    
}

