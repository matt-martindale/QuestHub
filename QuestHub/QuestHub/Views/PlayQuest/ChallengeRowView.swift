//
//  ChallengeRowView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/20/25.
//

import SwiftUI

struct ChallengeRowView: View {
    let challenge: Challenge
    let onTap: () -> Void = { }
    
    init(challenge: Challenge) {
        self.challenge = challenge
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.primary.opacity(0.1))
                    Image(systemName: challengeTypeIcon)
                        .font(.title3)
                        .foregroundStyle(Color.qhPrimaryBlue)
                }
                .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.title ?? "Title missing")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Text(challengeTypeLabel)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Text(String(challenge.points ?? 0) + " pts")
                    .font(.footnote)
                    .foregroundStyle(.primary)
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .padding(16)
        .background(
            Group {
                if challenge.completed ?? false {
                    Color.green.opacity(0.1)
                } else {
                    Color.clear
                }
            }
        )
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .glassEffect(in: .rect(cornerRadius: 14))
        .overlay(
            Group {
                if challenge.completed ?? false {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.green, lineWidth: 1.5)
                } else {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.clear, lineWidth: 1)
                }
            }
        )
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

#Preview {
    // Sample data for each challenge type
    let photo = Challenge(
        id: "c1",
        title: "Snap the Campus Mascot",
        details: "",
        points: 5,
        completed: false,
        challengeType: .photo(PhotoData())
    )

    let multipleChoice = Challenge(
        id: "c2",
        title: "Multiple choice question",
        details: "",
        points: 10,
        completed: false,
        challengeType: .multipleChoice(MultipleChoiceData())
    )

    let question = Challenge(
        id: "c3",
        title: "Name the protocol used for list diffing in SwiftUI.",
        details: "",
        points: 15,
        completed: true,
        challengeType: .question(QuestionData())
    )

    let prompt = Challenge(
        id: "c4",
        title: "Write a one-sentence app idea you wish existed.",
        details: "",
        points: 30,
        completed: true,
        challengeType: .prompt(PromptData())
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

