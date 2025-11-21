//
//  ChallengeDetailView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/20/25.
//

import SwiftUI

struct ChallengeDetailView: View {
    let challenge: Challenge
    
    var body: some View {
        Text(challenge.title ?? "")
    }
}

#Preview {
    let challenge = Challenge(
        id: "c3",
        title: "Name the protocol used for list diffing in SwiftUI.",
        details: "",
        points: 15,
        completed: true,
        challengeType: .question(QuestionData())
    )
    ChallengeDetailView(challenge: challenge)
}
