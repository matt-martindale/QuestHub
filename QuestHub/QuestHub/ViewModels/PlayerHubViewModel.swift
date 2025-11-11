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
    @Published var joinedQuests: [Quest] = []
    @Published var errorMessage: String?

    private var listener: ListenerRegistration?

    deinit {
        listener?.remove()
    }

    func startListeningForUserQuests(for uid: String) {
        // Remove any existing listener before starting a new one
        listener?.remove()
        errorMessage = nil
        isLoading = true

        let db = Firestore.firestore()
        listener = db.collection("userQuests")
            .whereField("userId", isEqualTo: uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                guard let documents = snapshot?.documents else {
                    self.joinedQuests = []
                    return
                }

                // Extract quest IDs (support both "questId" and "questID")
                let questIds: [String] = documents.compactMap { doc in
                    if let qid = doc.data()["questId"] as? String { return qid }
                    if let qid = doc.data()["questID"] as? String { return qid }
                    return nil
                }

                guard !questIds.isEmpty else {
                    self.joinedQuests = []
                    return
                }

                // Firestore `in` queries support max 10 items; chunk IDs accordingly
                let chunkSize = 10
                let chunks: [[String]] = stride(from: 0, to: questIds.count, by: chunkSize).map { start in
                    Array(questIds[start..<min(start + chunkSize, questIds.count)])
                }

                var fetchedQuests: [Quest] = []
                var encounteredError: String?
                let group = DispatchGroup()

                for chunk in chunks {
                    group.enter()
                    db.collection("quests")
                        .whereField(FieldPath.documentID(), in: chunk)
                        .getDocuments { snap, err in
                            defer { group.leave() }

                            if let err = err {
                                let msg = err.localizedDescription
                                if let existing = encounteredError {
                                    encounteredError = existing + "\n" + msg
                                } else {
                                    encounteredError = msg
                                }
                                return
                            }

                            guard let docs = snap?.documents else { return }

                            // Decode documents into Quest using FirestoreDecodable
                            let quests: [Quest] = docs.compactMap { doc in
                                do {
                                    return try doc.data(as: Quest.self)
                                } catch {
                                    print("Failed to decode Quest: \(error)")
                                    return nil
                                }
                            }

                            fetchedQuests.append(contentsOf: quests)
                        }
                }

                group.notify(queue: .main) {
                    if let msg = encounteredError {
                        self.errorMessage = msg
                    }

                    // Preserve the order of questIds when assigning
                    let fetchedById: [String: Quest] = Dictionary(uniqueKeysWithValues: fetchedQuests.compactMap { q in
                        guard let qid = q.id, !qid.isEmpty else { return nil }
                        return (qid, q)
                    })

                    self.joinedQuests = questIds.compactMap { fetchedById[$0] }
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
        isLoading = false
        errorMessage = nil
    }
}
