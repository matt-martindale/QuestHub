//
//  ChallengeRowView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/20/25.
//

import SwiftUI

struct ChallengeRowView: View {
    let challenge: Challenge
    
    init(challenge: Challenge) {
        self.challenge = challenge
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "flag.checkered")
                .font(.title3)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 4) {
                Text(challenge.title ?? "")
                    .font(.headline)
//                Text("A brief description of what to do for this challenge.")
//                    .font(.subheadline)
//                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .glassEffect(in: .rect(cornerRadius: 14))
    }
}

#Preview {
    let challenge = Challenge(id: "1", title: "Test Challenge", details: "A test challenge", points: 15, completed: false, challengeType: .question(QuestionData(question: "Question", answer: "Answer")))
    ChallengeRowView(challenge: challenge)
}
