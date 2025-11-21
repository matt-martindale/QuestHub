//
//  ChallengeDetailView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/20/25.
//

import SwiftUI

struct ChallengeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let challenge: Challenge
    let onComplete: (Challenge) -> Void
    
    var body: some View {
        VStack {
            Text(challenge.title ?? "")
            Button {
                onComplete(challenge)
            } label: {
                Text("Complete Challenge")
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") {
                    dismiss()
                }
            }
        }
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
    ChallengeDetailView(challenge: challenge) { _ in }
}
