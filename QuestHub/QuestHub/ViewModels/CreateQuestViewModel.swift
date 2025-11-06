import Foundation
import SwiftUI
import Combine

@MainActor
final class CreateQuestViewModel: ObservableObject {
    // Navigation
    @Published var path: [String] = []

    // Quest fields
    @Published var title: String = ""
    @Published var subtitle: String = ""
    @Published var descriptionText: String = ""

    // Password
    @Published var isPasswordProtected: Bool = false
    @Published var password: String = ""
    @Published var showPasswordInfo: Bool = false

    // Challenges
    @Published var challenges: [Challenge] = []
    @Published var isPresentingCreateChallenge: Bool = false
    @Published var editingChallengeIndex: Int? = nil

    init() {}

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
}

