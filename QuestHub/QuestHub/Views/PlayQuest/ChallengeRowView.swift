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
            Image(systemName: challengeTypeIcon)
                .font(.title3)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 4) {
                Text(challenge.title ?? "")
                    .font(.headline)
                Text(challengeTypeLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
    
    private var challengeTypeIcon: String {
        switch challenge.challengeType {
        case .photo: return "camera"
        case .multipleChoice: return "list.bullet.rectangle.portrait"
        case .question: return "questionmark.circle"
        case .prompt: return "square.and.pencil"
        }
    }

    private var challengeTypeLabel: String {
        switch challenge.challengeType {
        case .photo: return "Photo"
        case .multipleChoice: return "Multiple choice"
        case .question: return "Question"
        case .prompt: return "Prompt"
        }
    }
}

#Preview("Challenge row examples") {
    // Sample data for each challenge type
    let photo = Challenge(
        id: "c1",
        title: "Snap the Campus Mascot",
        details: "Take a photo with the mascot statue.",
        points: 25,
        completed: false,
        challengeType: .photo(PhotoData(imageURL: "imageURL", prompt: "Take a photo of a sunset", caption: "caption"))
    )

    let multipleChoice = Challenge(
        id: "c2",
        title: "Swift Basics",
        details: "Which keyword creates a constant?",
        points: 10,
        completed: false,
        challengeType: .multipleChoice(
            MultipleChoiceData(
                question: "Which keyword creates a constant?",
                answers: ["var", "let", "const", "static"],
                correctAnswer: "let"
            )
        )
    )

    let question = Challenge(
        id: "c3",
        title: "Short Answer",
        details: "Name the protocol used for list diffing in SwiftUI.",
        points: 15,
        completed: true,
        challengeType: .question(
            QuestionData(
                question: "What protocol enables identity in SwiftUI lists?",
                answer: "Identifiable"
            )
        )
    )

    let prompt = Challenge(
        id: "c4",
        title: "Daily Prompt",
        details: "Write a one-sentence app idea you wish existed.",
        points: 5,
        completed: true,
        challengeType: .prompt(
            PromptData(prompt: "Describe an app idea in one sentence.")
        )
    )

    ScrollView {
        VStack(spacing: 12) {
            ChallengeRowView(challenge: photo)
            ChallengeRowView(challenge: multipleChoice)
            ChallengeRowView(challenge: question)
            ChallengeRowView(challenge: prompt)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}
