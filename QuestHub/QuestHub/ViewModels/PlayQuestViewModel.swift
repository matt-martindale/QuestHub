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
    @Published var quest: Quest
    
    init(quest: Quest) {
        self.quest = quest
    }
    
    var questDescription: String {
        if let questDescription = quest.description, !questDescription.isEmpty {
            return questDescription
        }
        return "Get ready to explore, solve challenges, and progress through this quest. Complete tasks, earn points, and uncover surprises along the way!"
    }
}
