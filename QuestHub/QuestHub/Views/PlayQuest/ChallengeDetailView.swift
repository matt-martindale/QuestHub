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

    @State private var questionAnswer: String = ""
    @State private var prompt: String = ""
    @State private var photoPrompt: String = ""
    
    @State private var inputAnswer: String = ""
    @State private var inputPrompt: String = ""
    @State private var selectedChoice: String = ""
    @State private var imageURLText: String = ""
    @State private var captionText: String = ""
    @State private var attemptedSubmit: Bool = false

    // MARK: - Validation
    private enum ValidationState {
        case valid
        case invalid(message: String)

        var isValid: Bool {
            if case .valid = self { return true }
            return false
        }
    }

    private var validation: ValidationState {
        switch challenge.challengeType {
        case .question(let data):
            let expected = (data.answer ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            let provided = inputAnswer
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            if provided.isEmpty {
                return .invalid(message: "Please provide an answer.")
            }
            return provided == expected ? .valid : .invalid(message: "That doesn’t look right.")

        case .multipleChoice(let data):
            if selectedChoice.isEmpty {
                return .invalid(message: "Select an option.")
            }
            if let correct = data.correctAnswer, selectedChoice == correct {
                return .valid
            } else if data.correctAnswer != nil {
                return .invalid(message: "Try another choice.")
            } else {
                // If no correct answer is provided, treat any selection as valid input
                return .valid
            }

        case .prompt:
            let text = inputPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? .invalid(message: "Please enter a response.") : .valid

        case .photo:
            let urlText = imageURLText.trimmingCharacters(in: .whitespacesAndNewlines)
            let caption = captionText.trimmingCharacters(in: .whitespacesAndNewlines)
            if urlText.isEmpty { return .invalid(message: "Add an image URL.") }
            if caption.isEmpty { return .invalid(message: "Add a caption.") }
            return .valid
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()

            contentView()
                .onAppear { populateStateFromChallenge() }
                .onChange(of: inputAnswer) { _ in resetAttemptedSubmit() }
                .onChange(of: selectedChoice) { _ in resetAttemptedSubmit() }
                .onChange(of: inputPrompt) { _ in resetAttemptedSubmit() }
                .onChange(of: imageURLText) { _ in resetAttemptedSubmit() }
                .onChange(of: captionText) { _ in resetAttemptedSubmit() }

            if attemptedSubmit, case .invalid(let message) = validation {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button {
                attemptedSubmit = true
                if validation.isValid {
                print("Answer is correct")
                    onComplete(challenge)
                }
            } label: {
                Text("Submit")
                    .frame(maxWidth: .infinity)
            }
            .padding()
            .buttonStyle(.borderedProminent)
            
            Spacer()
            Spacer()
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { dismiss() }
            }
        }
    }

    @ViewBuilder
    private func contentView() -> some View {
        switch challenge.challengeType {
        case .question(let data):
            QuestionView(
                question: data.question ?? "Question",
                answer: data.answer ?? "Answer",
                inputAnswer: $inputAnswer
            )
        case .multipleChoice(let data):
            MultipleChoiceView(
                question: data.question ?? "Question",
                answers: data.answers ?? [],
                selectedChoice: $selectedChoice
            )
        case .prompt(let data):
            PromptView(
                prompt: data.prompt ?? "Prompt",
                inputPrompt: $inputPrompt
            )
        case .photo(let data):
            PhotoView(
                prompt: data.prompt ?? "Photo Challenge",
                imageURLText: $imageURLText,
                captionText: $captionText
            )
        }
    }

    private func populateStateFromChallenge() {
        switch challenge.challengeType {
        case .question(let q):
            questionAnswer = q.answer ?? ""
        case .multipleChoice(let mc):
            selectedChoice = mc.correctAnswer ?? ""
        case .prompt(let p):
            prompt = p.prompt ?? ""
        case .photo(let p):
            photoPrompt = p.prompt ?? ""
        }
    }
    
    private func resetAttemptedSubmit() {
        if attemptedSubmit {
            attemptedSubmit = false
        }
    }
    
    private struct QuestionView: View {
        let question: String
        let answer: String
        @Binding var inputAnswer: String

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text(question)
                    .font(.title3)
                Text("*not case-sensitive")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                    .frame(height: 12)
                TextField("Type your answer…", text: $inputAnswer)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
}

private struct MultipleChoiceView: View {
    let question: String
    let answers: [String]
    @Binding var selectedChoice: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question)
                .font(.headline)
            if answers.isEmpty {
                Text("No answers available")
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(answers, id: \.self) { option in
                        HStack {
                            Image(systemName: selectedChoice == option ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(.tint)
                            Text(option)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { selectedChoice = option }
                    }
                }
                .padding(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3))
                )
            }
        }
    }
}

private struct PromptView: View {
    let prompt: String
    @Binding var inputPrompt: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(prompt)
                .font(.headline)
            Text("Your Response")
                .font(.headline)
            TextField("Type your response…", text: $inputPrompt)
                .textFieldStyle(.roundedBorder)
        }
    }
}

private struct PhotoView: View {
    let prompt: String
    @Binding var imageURLText: String
    @Binding var captionText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(prompt)
                .font(.headline)
            TextField("Image URL", text: $imageURLText)
                .textFieldStyle(.roundedBorder)
            Text("Caption")
                .font(.headline)
            TextField("Add a caption…", text: $captionText)
                .textFieldStyle(.roundedBorder)
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
        challengeType: .question(QuestionData(question: "Who is Seinfelds best friend", answer: "George"))
    )
    ChallengeDetailView(challenge: challenge) { _ in }
}

