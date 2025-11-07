//
//  InfoSheetViewModel.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/6/25.
//

import Foundation
import SwiftUI
import Combine

enum InfoFlow: Equatable {
    case password
    case maxPlayers
}

@MainActor
final class InfoSheetViewModel: ObservableObject {
    
    @Published var flow: InfoFlow

    init(flow: InfoFlow) {
        self.flow = flow
    }

    var titleText: String {
        switch flow {
        case .password:
            "Password protection"
        case .maxPlayers:
            "Maximum # of players"
        }
    }

    var infoText: String {
        switch flow {
        case .password:
            return "When enabled, players must enter this password to join your quest. Share the password only with the people you wish to participate."
        case .maxPlayers:
            return "Set the maximum number of players who can join your quest. Once the limit is reached, no additional players will be able to join. You can adjust this later."
        }
    }
}

