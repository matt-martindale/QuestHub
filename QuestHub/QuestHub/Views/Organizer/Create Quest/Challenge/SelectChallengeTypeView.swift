//
//  SelectChallengeTypeView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/17/25.
//

import SwiftUI

struct SelectChallengeTypeView: View {
    @Environment(\.dismiss) private var dismiss

    // The selected type is managed locally and passed forward on confirm.
    @State private var selectedType: ChallengeType? = nil
    @State private var navigateToCreate: Bool = false
    let completion: (CreateChallengeResult) -> Void
    
    init(completion: @escaping (CreateChallengeResult) -> Void) {
        self.completion = completion
    }

    // Since ChallengeType has associated values, it cannot be CaseIterable. Provide explicit options here.
    private let availableTypes: [ChallengeType] = [
        .photo(PhotoData(imageURL: nil, caption: nil)),
        .multipleChoice(MultipleChoiceData(question: nil, answers: nil, correctAnswer: nil)),
        .question(QuestionData(question: nil, answer: nil))
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Choose a challenge type")
                    .font(.title2.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Grid/List of card options
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(availableTypes, id: \.self) { type in
                            ChallengeTypeCardView(
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        completion(.cancel)
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func destinationView() -> some View {
        if let selectedType {
            CreateChallengeView(challengeType: selectedType, challenge: nil) { createChallengeResult in
                switch createChallengeResult {
                case .save(let challenge):
                    completion(.save(challenge))
                    dismiss()
                case .cancel:
                    completion(.cancel)
                    dismiss()
                case .delete:
                    completion(.delete)
                    dismiss()
                }
            }
        } else {
            EmptyView()
        }
    }
}

#Preview {
    SelectChallengeTypeView { _ in }
}

