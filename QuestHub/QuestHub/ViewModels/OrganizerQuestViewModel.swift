//
//  OrganizerQuestViewModel.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/19/25.
//

import Foundation
import Combine

@MainActor
final class OrganizerQuestViewModel: ObservableObject {
    @Published var quest: Quest
    @Published var status: QuestStatus?
    
    init(quest: Quest) {
        self.quest = quest
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
    
    var statusDetails: String {
        switch self.quest.status {
        case .active:
            "Live and ready phase! Players can join Quests. View and complete challenges."
        case .paused:
            "Preparation phase: Players can join Quests, but cannot view or complete challenges."
        case .closed:
            "Finished phase: New players cannot join, and cannot view or complete challenges."
        default:
            "Status unavailable. Please check back shortly."
        }
    }
    
    func updateQuestStatus() {
        guard let questId = quest.id , let status = status?.rawValue else { return }
        QuestService.shared.updateQuestStatus(questId: questId, statusString: status) { result in
            switch result {
            case .success(let status):
                DispatchQueue.main.async {
                    self.quest.status = status
                }
            case .failure(let error):
                print("Failed to update status:", error)
            }
        }
    }
}
