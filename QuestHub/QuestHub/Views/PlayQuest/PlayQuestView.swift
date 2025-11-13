//
//  PlayQuestView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/13/25.
//

import SwiftUI

struct PlayQuestView: View {
    let quest: Quest
    var body: some View {
        Text(quest.questCode ?? "")
    }
}

#Preview {
//    PlayQuestView()
}
