//
//  ChallengeTypeCardView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/17/25.
//

import SwiftUI

struct ChallengeTypeCardView: View {
    let type: ChallengeType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: iconName(for: type))
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                Text(title(for: type))
                    .font(.title3)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                if let subtitle = subtitle(for: type) {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: isSelected ? 3 : 1)
            )
            .aspectRatio(1, contentMode: .fit)
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func title(for type: ChallengeType) -> String {
        switch type {
        case .photo(_):
            return "Photo"
        case .question(_):
            return "Question"
        case .multipleChoice(_):
            return "Multiple Choice"
        case .prompt(_):
            return "Prompt"
        }
    }

    private func subtitle(for type: ChallengeType) -> String? {
        switch type {
        case .photo:
            return "Submit a photo"
        case .question:
            return "Answer question with a specific answer"
        case .multipleChoice:
            return "Select answer from multiple options"
        case .prompt:
            return "Respond with any answer"
        }
    }

    private func iconName(for type: ChallengeType) -> String {
        switch type {
        case .photo:
            return "camera"
        case .question:
            return "bubble.left.and.text.bubble.right"
        case .multipleChoice:
            return "list.bullet.rectangle"
        case .prompt:
            return "text.bubble"
        }
    }
}

#Preview {
    HStack {
        VStack {
            ChallengeTypeCardView(type: .multipleChoice(MultipleChoiceData()), isSelected: true) {}
            ChallengeTypeCardView(type: .photo(PhotoData()), isSelected: false) {}
        }
        VStack {
            ChallengeTypeCardView(type: .question(QuestionData()), isSelected: true) {}
            ChallengeTypeCardView(type: .prompt(PromptData()), isSelected: false) {}
        }
    }
    .padding()
}
