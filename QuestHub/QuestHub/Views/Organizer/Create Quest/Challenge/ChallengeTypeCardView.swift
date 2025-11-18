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
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title(for: type))
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if let subtitle = subtitle(for: type) {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                        .font(.title3)
                        .padding(6)
                        .background(Circle().fill(Color.accentColor))
                        .accessibilityLabel("Selected")
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(.tertiary)
                        .font(.title3)
                        .accessibilityHidden(true)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func title(for type: ChallengeType) -> String {
        String(describing: type).capitalized
    }

    private func subtitle(for type: ChallengeType) -> String? {
        nil
    }
}

#Preview {
    ChallengeTypeCardView(type: .multipleChoice(MultipleChoiceData()), isSelected: true) {}
    ChallengeTypeCardView(type: .photo(PhotoData()), isSelected: false) {}
    ChallengeTypeCardView(type: .question(QuestionData()), isSelected: true) {}
}
