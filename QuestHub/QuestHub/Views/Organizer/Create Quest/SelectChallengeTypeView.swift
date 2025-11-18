//
//  SelectChallengeTypeView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/17/25.
//

import SwiftUI

// Assumptions:
// - ChallengeType is an enum that conforms to CaseIterable & Identifiable or Hashable.
//   If it doesn't conform yet, this view uses Hashable for selection and ForEach id: \.self.
// - CreateChallengeView(challengeType:) is an existing destination view that accepts a ChallengeType.

struct SelectChallengeTypeView: View {
    let types: [ChallengeType]
    // The selected type is managed locally and passed forward on confirm.
    @State private var selectedType: ChallengeType? = nil
    @State private var navigateToCreate: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Choose a challenge type")
                    .font(.title2.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Grid/List of card options
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(types, id: \.self) { type in
                            ChallengeTypeCard(
                                type: type,
                                isSelected: selectedType == type
                            ) {
                                withAnimation(.snappy) {
                                    selectedType = type
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Confirm button
                Button {
                    guard selectedType != nil else { return }
                    navigateToCreate = true
                } label: {
                    Text("Confirm")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedType == nil ? Color.gray.opacity(0.3) : Color.accentColor)
                        .foregroundColor(selectedType == nil ? .secondary : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(selectedType == nil)
            }
            .padding()
            .navigationTitle("New Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .background(
                NavigationLink(
                    destination: destinationView(),
                    isActive: $navigateToCreate,
                    label: { EmptyView() }
                )
                .opacity(0)
            )
        }
    }

    @ViewBuilder
    private func destinationView() -> some View {
        if let selectedType {
            CreateChallengeView(challengeType: selectedType, challenge: nil) {_ in }
        } else {
            EmptyView()
        }
    }
}

private struct ChallengeTypeCard: View {
    let type: ChallengeType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Optional icon/title derived from type; replace with your own mapping as needed
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
        // Provide readable titles per type. Adjust as needed based on your enum.
        String(describing: type).capitalized
    }

    private func subtitle(for type: ChallengeType) -> String? {
        // Optional helper for subtitles per type.
        nil
    }
}

#Preview {
    // Supply a concrete ChallengeType for preview to fix the missing argument error.
    // Replace `.allCases.first!` with a specific case if desired, e.g., `.fitness`.
    SelectChallengeTypeView(types: [])
}
