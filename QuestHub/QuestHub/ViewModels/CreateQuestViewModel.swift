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
    @Published var maxPlayers: Int? = nil
    @Published var isPasswordProtected: Bool = false
    @Published var password: String = ""
    @Published var challenges: [Challenge] = []
    @Published var isPresentingCreateChallenge: Bool = false
    @Published var editingChallengeIndex: Int? = nil
    @Published var isEditing: Bool = false

    private var editingQuestID: String? = nil

    let auth: QHAuth
    private let firestore: FirestoreService

    @Published var isSaving: Bool = false
    @Published var didFinishSaving: Bool = false

    // We require the shared auth instance to be injected to avoid creating multiple instances and missing UI updates.
    init(auth: QHAuth, questToEdit: Quest? = nil, firestore: FirestoreService = FirestoreService()) {
        self.auth = auth
        self.firestore = firestore
        if let quest = questToEdit {
            // Prefill fields for editing
            self.isEditing = true
            self.title = quest.title ?? ""
            self.subtitle = quest.subtitle ?? ""
            self.descriptionText = quest.details ?? ""
            self.isPasswordProtected = quest.isLocked ?? false
            self.password = quest.password ?? ""
            // Map quest challenges to local Challenge model if available
            if let questChallenges = quest.challenges {
                self.challenges = questChallenges.map { qc in
                    let title = qc.title ?? ""
                    let details = qc.details ?? ""
                    let points = qc.points ?? 0
                    let id: String = qc.id ?? IDGenerator.makeShortID()
                    return Challenge(
                        id: id,
                        title: title,
                        details: details,
                        points: points,
//                        challengeType: .question(QuestionData(prompt: "prompt", answer: "answer")
//                                                )
                    )
                }
            }
            self.editingQuestID = quest.id
        }
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

            // Determine whether we're creating a new quest or updating an existing one
            let db = FirebaseFirestore.Firestore.firestore()
            let userQuests = db.collection("users").document(user.id).collection("quests")

            let isUpdating = (editingQuestID != nil)
            let questID = editingQuestID ?? IDGenerator.makeShortID()

            // Build quest dictionary for Firestore (align with your Firestore schema)
            var data: [String: Any] = [
                "id": questID,
                "title": title.trimmingCharacters(in: .whitespacesAndNewlines),
                "subtitle": subtitle.trimmingCharacters(in: .whitespacesAndNewlines),
                "details": descriptionText.trimmingCharacters(in: .whitespacesAndNewlines),
                "creatorID": user.id,
                "creatorDisplayName": user.displayName ?? user.email ?? "anonymous",
                "isLocked": isPasswordProtected,
                "password": isPasswordProtected ? password : "",
                "challenges": challenges.map { ch in
                    return [
                        "id": ch.id,
                        "title": ch.title,
                        "details": ch.details,
                        "points": ch.points
                    ]
                }
            ]

            if isUpdating {
                data["updatedAt"] = Date()
            } else {
                data["createdAt"] = Date()
            }

            do {
                if isUpdating, let questID = editingQuestID {
                    // Overwrite existing quest document (merge to preserve any fields we didn't specify if needed)
                    try await userQuests.document(questID).setData(data, merge: true)
                } else {
                    // Create new quest with known id so future edits can target this document
                    try await userQuests.document(questID).setData(data)
                    // Store the new id for any further edits in this session
                    self.editingQuestID = questID
                }

                // Refresh user's quests in auth
                do {
                    let latest = try await firestore.fetchQuests(forUserID: user.id)
                    auth.updateCurrentUserQuests(latest)
                } catch {
                    // Non-fatal; proceed with navigation
                }

                didFinishSaving = true
            } catch {
                // TODO: Surface error to UI if desired
                print("Failed to save quest: \(error)")
            }
        }
    }
}
