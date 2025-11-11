//
//  SearchQuestResultsViewModel.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/11/25.
//

import Foundation
import Combine

@MainActor
final class SearchQuestResultsViewModel: ObservableObject {
    let auth: QHAuth
    let quest: Quest
    
    init(auth: QHAuth, quest: Quest) {
        self.auth = auth
        self.quest = quest
    }
}
