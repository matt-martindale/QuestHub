//
//  PlayerHubViewModel.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/10/25.
//

import Foundation
import SwiftUI
import Combine
import FirebaseFirestore

@MainActor
final class PlayerHubViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var hasJoinedQuests: Bool = false
    @Published var errorMessage: String?

    private var listener: ListenerRegistration?

    deinit {
        listener?.remove()
    }

    func startListeningForUserQuests(for uid: String) {
        // Remove any existing listener before starting a new one
        listener?.remove()
        errorMessage = nil
        hasJoinedQuests = false
        isLoading = true

        let db = Firestore.firestore()
        listener = db.collection("userQuests")
            .whereField("userId", isEqualTo: uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.hasJoinedQuests = false
                    return
                }
                let count = snapshot?.documents.count ?? 0
                self.hasJoinedQuests = count > 0
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
        isLoading = false
        hasJoinedQuests = false
        errorMessage = nil
    }
}
