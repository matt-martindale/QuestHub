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
    @Published var isJoined: Bool = false
    @Published var quest: Quest
    @Published var inputPassword: String = ""
    @Published var alertMessage: AlertMessage?
    @Published var showingPasswordSheet: Bool = false
    @Published var passwordError: String? = nil
    @Published var isJoining: Bool = false
    @Published var showingLeaveConfirmation: Bool = false
    @Published var userChallenges: [Challenge] = []
    @Published var points: Int = 10
    @Published var isLoadingChallenges: Bool = false
    
    init(quest: Quest) {
        self.quest = quest
        // We no longer determine isJoined state here since we have no user info.
        // Use refreshJoinedState(for:) with a user ID when available.
    }
    
    func refreshJoinedState(for userId: String?) {
        guard let uid = userId, let qid = quest.id, !uid.isEmpty, !qid.isEmpty else {
            self.isJoined = false
            return
        }
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let joined = try await QuestService.shared.hasJoinedQuest(userId: uid, questId: qid)
                self.isJoined = joined
                if joined { self.loadUserChallenges(for: uid) } else { self.userChallenges = [] }
            } catch {
                print("hasJoinedQuest check failed: \(error.localizedDescription)")
            }
        }
    }
    
    func loadUserChallenges(for userId: String?) {
        guard let uid = userId, let qid = quest.id, !uid.isEmpty, !qid.isEmpty else {
            self.userChallenges = []
            return
        }
        isLoadingChallenges = true
        QuestService.shared.fetchUserChallenges(userId: uid, questId: qid) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoadingChallenges = false
                switch result {
                case .success(let challenges):
                    self.userChallenges = challenges
                case .failure(let error):
                    print("Failed to load user challenges: \(error.localizedDescription)")
                    self.userChallenges = []
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
    func beginJoinFlow(currentUser: QHUser?) {
        alertMessage = nil
        if currentUser == nil {
            self.alertMessage = AlertMessage(text: "Please sign in or create an account to join a quest.")
            isJoining = false
            return
        }
        if requiresPassword() && inputPassword.isEmpty {
            showingPasswordSheet = true
            return
        }
        joinQuest(currentUser: currentUser)
    }
    
    func confirmPasswordAndJoin(currentUser: QHUser?) {
        let requiredPassword = (quest.password ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let inputPassword = inputPassword.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if inputPassword == requiredPassword {
            passwordError = nil
            joinQuest(currentUser: currentUser)
            showingPasswordSheet = false
        } else {
            passwordError = "Incorrect password. Please try again."
        }
    }
    
    // MARK: Actions
    
    func joinQuest(currentUser: QHUser?) {
        guard let questID = quest.id,
              let questCode = quest.questCode else { return }
        alertMessage = nil
        isJoining = true
        
        if currentUser == nil {
            self.alertMessage = AlertMessage(text: "Please sign in or create an account to join a quest.")
            isJoining = false
            return
        }
        
        // Join Quest after passing validations
        QuestService.shared.joinQuest(questId: questID, questCode: questCode, userId: currentUser?.id, userDisplayName: currentUser?.displayName ?? currentUser?.email ?? "anonymous", maxPlayersEnforced: true) { result in
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
                self.loadUserChallenges(for: currentUser?.id)
            case .failure(let error):
                self.isJoining = false
                self.alertMessage = AlertMessage(text: error.localizedDescription)
            }
        }
    }
    
    func leaveQuest(currentUser: QHUser?) {
        print("Leaving quest")
        guard let questID = quest.id,
              let userId = currentUser?.id else {
            return
        }
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

extension PlayQuestViewModel {
    // Called by the view on appear/task to initialize state
    func onAppear(userId: String?) {
        refreshJoinedState(for: userId)
        fetchPoints(userId: userId)
    }

    // Called by the view's pull-to-refresh
    func refresh(userId: String?) {
        refreshQuestAndChallenges(userId: userId)
        fetchPoints(userId: userId)
    }

    // Orchestrates refreshing quest metadata and reloading per-user challenges
    func refreshQuestAndChallenges(userId: String?) {
        guard let code = quest.questCode, !code.isEmpty else {
            // If there's no quest code, just reload challenges
            loadUserChallenges(for: userId)
            return
        }
        QuestService.shared.searchQuest(byCode: code) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let refreshed):
                    if let currentId = self.quest.id, let newId = refreshed.id, currentId == newId {
                        self.quest = refreshed
                    }
                case .failure:
                    break
                }
                self.loadUserChallenges(for: userId)
            }
        }
    }
    
    func fetchPoints(userId: String?) {
        guard let userId = userId,
              let questId = quest.id else { return }
        QuestService.shared.fetchUserQuestPoints(userId: userId, questId: questId) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let points):
                    self.points = points
                case .failure:
                    break
                }
            }
        }
    }
    
}
