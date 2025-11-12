//
//  PlayerHubViewModel.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/10/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class PlayerHubViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var joinedQuests: [Quest] = []
    @Published var errorMessage: String?

    private let service = QuestService.shared

    func startListeningForUserQuests(for uid: String) {
        errorMessage = nil
        isLoading = true

        service.startListeningForJoinedQuests(uid: uid) { [weak self] quests, error in
            guard let self = self else { return }
            self.isLoading = false
            if let error = error, !error.isEmpty {
                self.errorMessage = error
            }
            self.joinedQuests = quests
        }
    }

    func stopListening() {
        service.stopListeningForJoinedQuests()
        isLoading = false
        errorMessage = nil
    }
}
