import Foundation
import SwiftUI
import Combine
import FirebaseFirestore

@MainActor
final class CreateQuestViewModel: ObservableObject {
    @Published var path: [String] = []
    @Published var title: String = ""
    @Published var subtitle: String = ""
    @Published var descriptionText: String = ""
    @Published var isPasswordProtected: Bool = false
    @Published var password: String = ""
    @Published var showPasswordInfo: Bool = false
    @Published var challenges: [Challenge] = []
    @Published var isPresentingCreateChallenge: Bool = false
    @Published var editingChallengeIndex: Int? = nil

    let auth: QHAuth
    private let firestore: FirestoreService

    @Published var isSaving: Bool = false

    // We require the shared auth instance to be injected to avoid creating multiple instances and missing UI updates.
    init(auth: QHAuth, firestore: FirestoreService = FirestoreService()) {
        self.auth = auth
        self.firestore = firestore
    }

    // MARK: - Challenge actions
    func beginAddChallenge() {
        editingChallengeIndex = nil
        isPresentingCreateChallenge = true
    }

    func beginEditChallenge(at index: Int) {
        guard challenges.indices.contains(index) else { return }
        editingChallengeIndex = index
        isPresentingCreateChallenge = true
    }

    func handleChallengeResult(_ result: CreateChallengeView.Result) {
        switch result {
        case .save(let newChallenge):
            if let idx = editingChallengeIndex, challenges.indices.contains(idx) {
                challenges[idx] = newChallenge
            } else {
                challenges.append(newChallenge)
            }
        case .cancel:
            break
        case .delete:
            if let idx = editingChallengeIndex, challenges.indices.contains(idx) {
                challenges.remove(at: idx)
            }
        }
        editingChallengeIndex = nil
    }

    func moveChallenges(from offsets: IndexSet, to destination: Int) {
        challenges.move(fromOffsets: offsets, toOffset: destination)
    }

    // MARK: - Save
    var canSave: Bool {
        let hasTitle = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasAtLeastOneChallenge = !challenges.isEmpty
        let passwordOK = !isPasswordProtected || !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasTitle && hasAtLeastOneChallenge && passwordOK
    }

    func saveQuest() {
        guard canSave else { return }
        isSaving = true
        Task { @MainActor in
            defer { isSaving = false }
            guard let user = auth.currentUser else { return }

            // Build quest dictionary for Firestore (align with your Firestore schema)
            let data: [String: Any] = [
                "title": title.trimmingCharacters(in: .whitespacesAndNewlines),
                "subtitle": subtitle.trimmingCharacters(in: .whitespacesAndNewlines),
                "details": descriptionText.trimmingCharacters(in: .whitespacesAndNewlines),
                "createdAt": Date(),
                "creatorID": user.id,
                "creatorDisplayName": user.displayName ?? user.email ?? "anonymous",
                "isLocked": isPasswordProtected,
                "password": isPasswordProtected ? password : "",
                "challenges": challenges.map { ch in
                    return [
                        "id": ch.id.uuidString,
                        "title": ch.title,
                        "details": ch.details,
                        "points": ch.points
                    ]
                }
            ]

            do {
                let db = FirebaseFirestore.Firestore.firestore()
                let collection = db.collection("users").document(user.id).collection("quests")
                _ = try await collection.addDocument(data: data)
                
                // Removed parameterless updateCurrentUserQuests() call; use fetched latest instead
                do {
                    let latest = try await firestore.fetchQuests(forUserID: user.id)
                    auth.updateCurrentUserQuests(latest)
                } catch {
                    // Non-fatal; proceed with navigation
                }

                // Navigate back by clearing path
                path.removeAll()
            } catch {
                // TODO: Surface error to UI if desired
                print("Failed to save quest: \(error)")
            }
        }
    }
}

