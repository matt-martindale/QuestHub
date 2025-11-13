import Foundation
import SwiftUI
import Combine
import FirebaseStorage
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
    @Published var lastSavedQuest: Quest?
    // Image handling
    @Published var pendingCoverImageData: Data? = nil
    @Published var coverImageURL: URL? = nil

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
    private let questService: QuestService
    private var cancellables: Set<AnyCancellable> = []

    @Published var isSaving: Bool = false
    @Published var didFinishSaving: Bool = false
    @Published var didFinishDeleting: Bool = false

    init(auth: QHAuth, questToEdit: Quest? = nil, questService: QuestService) {
        self.auth = auth
        self.questService = questService
        if let quest = questToEdit {
            // Prefill fields for editing
            self.isEditing = true
            self.title = quest.title ?? ""
            self.subtitle = quest.subtitle ?? ""
            self.descriptionText = quest.description ?? ""
            self.isPasswordProtected = !(quest.password ?? "").isEmpty ? true : false
            self.password = quest.password ?? ""
            self.requireSignIn = quest.requireSignIn ?? false
            
            // Prefetch existing cover image data if available
            if let urlString = quest.imageURL, let url = URL(string: urlString) {
                Task { @MainActor in
                    do {
                        let (data, _) = try await URLSession.shared.data(from: url)
                        self.pendingCoverImageData = data
                    } catch {
                        // Ignore failures; UI will show placeholder
                    }
                }
            }
            
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
        self.init(auth: auth, questToEdit: questToEdit, questService: QuestService.shared)
    }

    // MARK: - Image Upload (Deferred)
    /// Call this if you ever want to trigger an upload outside of save; currently we defer until save.
    func uploadQuestImage(data: Data) async {
        await MainActor.run { self.pendingCoverImageData = data }
        // Intentionally no immediate upload; will upload during saveQuest().
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

            // Upload cover image if present
            if let imageData = self.pendingCoverImageData {
                do {
                    let url = try await self.uploadCoverImageToStorage(imageData: imageData, userID: user.id)
                    self.coverImageURL = url
                    // Assign to quest model if it has a field for image URL
                    questToSave.imageURL = url.absoluteString
                } catch {
                    print("Failed to upload cover image: \(error)")
                }
            }

            do {
                let savedID = try await questService.saveQuest(questToSave)
                self.editingQuestID = savedID
                self.lastSavedQuest = questToSave
                self.lastSavedQuest?.questCode = savedID

                // Clear pending image data after successful save
                self.pendingCoverImageData = nil

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
    
    func deleteQuest() {
        guard let questID = editingQuestID else { return }
        isSaving = true
        Task { @MainActor in
            defer { isSaving = false }
            do {
                try await questService.deleteQuest(withID: questID)
                // Refresh user's quests via auth so UI can reflect changes
                do { _ = await auth.fetchCreatedQuests() }
                didFinishDeleting = true
            } catch {
                print("Failed to delete quest: \(error)")
            }
        }
    }

    // MARK: - Private Helpers
    private func uploadCoverImageToStorage(imageData: Data, userID: String) async throws -> URL {
        // Use existing quest ID if editing; otherwise, generate a provisional one for the filename
        let questIDForFilename = UUID().uuidString
        let fileName = questIDForFilename + ".jpg"
        let path = "quests/\(userID)/\(fileName)"

        // Reference the default app's storage bucket
        let storageRef = Storage.storage().reference().child(path)

        // Set metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        // Upload data asynchronously
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)

        // Retrieve a public download URL
        let url = try await storageRef.downloadURL()
        return url
    }
}
