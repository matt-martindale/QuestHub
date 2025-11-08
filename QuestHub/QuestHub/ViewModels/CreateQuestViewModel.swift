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
    @Published var maxPlayersSelection: Int = 0
    @Published var requireSignIn: Bool = false
    @Published var isPasswordProtected: Bool = false
    @Published var password: String = ""
    @Published var challenges: [Challenge] = []
    @Published var isPresentingCreateChallenge: Bool = false
    @Published var editingChallengeIndex: Int? = nil
    @Published var isEditing: Bool = false

    var maxPlayers: Int {
        switch maxPlayersSelection {
        case 0: return 10
        case 1: return 100
        case 2: return 1000 // use a high cap to represent 100+
        default: return 10
        }
    }

    private var editingQuestID: String? = nil

    let auth: QHAuth
    private let firestore: FirestoreService
    private var cancellables: Set<AnyCancellable> = []

    @Published var isSaving: Bool = false
    @Published var didFinishSaving: Bool = false

    init(auth: QHAuth, questToEdit: Quest? = nil, firestore: FirestoreService) {
        self.auth = auth
        self.firestore = firestore
        if let quest = questToEdit {
            // Prefill fields for editing
            self.isEditing = true
            self.title = quest.title ?? ""
            self.subtitle = quest.subtitle ?? ""
            self.descriptionText = quest.description ?? ""
            self.isPasswordProtected = !(quest.password ?? "").isEmpty ? true : false
            self.password = quest.password ?? ""
            self.requireSignIn = quest.requireSignIn ?? false
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
            // Map an existing quest's max players to a selection if available
            if let existingMax = quest.maxPlayers {
                if existingMax <= 10 {
                    self.maxPlayersSelection = 0
                } else if existingMax <= 100 {
                    self.maxPlayersSelection = 1
                } else {
                    self.maxPlayersSelection = 2
                }
            }
        } else {
            // New quest defaults
            self.maxPlayersSelection = 0
        }
    }
    
    convenience init(auth: QHAuth, questToEdit: Quest? = nil) {
        self.init(auth: auth, questToEdit: questToEdit, firestore: FirestoreService())
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

            let creatorDisplayName = user.displayName ?? user.email ?? "anonymous"

            let trimmedTitle = self.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedSubtitle = self.subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedDescription = self.descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)

            let questToSave = Quest()
            questToSave.id = self.editingQuestID
            questToSave.title = trimmedTitle
            questToSave.subtitle = trimmedSubtitle
            questToSave.description = trimmedDescription
            questToSave.maxPlayers = self.maxPlayers
            questToSave.creatorID = user.id
            questToSave.creatorDisplayName = creatorDisplayName
            questToSave.status = .paused
            questToSave.password = self.password
            questToSave.requireSignIn = self.requireSignIn
            questToSave.challenges = self.challenges

            do {
                let savedID = try await firestore.saveQuest(questToSave)
                self.editingQuestID = savedID

                // Refresh user's quests via auth so UI can reflect changes
                do {
                    _ = await auth.fetchCreatedQuests()
                }

                didFinishSaving = true
            } catch {
                // TODO: Surface error to UI if desired
                print("Failed to save quest: \(error)")
            }
        }
    }
}

