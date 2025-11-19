import SwiftUI

struct CreateChallengeView: View {

    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: CreateChallengeViewModel

    let completion: (CreateChallengeResult) -> Void

    init(challengeType: ChallengeType?, challenge: Challenge?, completion: @escaping (CreateChallengeResult) -> Void) {
        _viewModel = StateObject(wrappedValue: CreateChallengeViewModel(challengeType: challengeType, challenge: challenge))
        self.completion = completion
    }

    var body: some View {
        NavigationStack {
            Text(viewModel.typeTitle)
                .font(.title2.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
            Form {
                VStack {
                    Text("Points")
                        .font(.subheadline.weight(.semibold))
                    Picker("Points", selection: $viewModel.points) {
                        Text("5").tag(5)
                        Text("10").tag(10)
                        Text("15").tag(15)
                        Text("30").tag(30)
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                typeSpecificForm()
                if viewModel.existingChallenge != nil {
                    Section {
                        Button(role: .destructive) {
                            completion(.delete)
                            dismiss()
                        } label: {
                            Label("Delete Challenge", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewModel.existingChallenge != nil {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            completion(.cancel)
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let challenge = viewModel.buildChallenge()
                        completion(.save(challenge))
                        dismiss()
                    }
                    .disabled(viewModel.isSaveDisabled)
                }
            }
        }
    }

    @ViewBuilder
    private func typeSpecificForm() -> some View {
        switch viewModel.challengeType {
        case .photo:
            Section(header: Text("Enter Prompt")) {
                TextField("Ex: Take a photo of a sunset", text: $viewModel.photoPrompt)
                    .textInputAutocapitalization(.sentences)
            }
        case .multipleChoice:
            Section(header: Text("Question")) {
                TextField("Enter question", text: $viewModel.mcQuestion)
            }
            Section(header: Text("Options")) {
                ForEach(viewModel.mcAnswers.indices, id: \.self) { idx in
                    HStack {
                        TextField("Option \(idx + 1)", text: Binding(
                            get: { idx < viewModel.mcAnswers.count ? viewModel.mcAnswers[idx] : "" },
                            set: { newValue in
                                if idx < viewModel.mcAnswers.count { viewModel.mcAnswers[idx] = newValue }
                            }
                        ))
                        .textInputAutocapitalization(.sentences)

                        if viewModel.mcAnswers.count > 2 { // allow removing down to 2 options minimum
                            Button(role: .destructive) {
                                if idx < viewModel.mcAnswers.count {
                                    viewModel.mcAnswers.remove(at: idx)
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Button("Add Option") {
                    viewModel.mcAnswers.append("")
                }
                .disabled(viewModel.mcAnswers.count >= 8)
            }
                
                Section(header: Text("Answer")) {
                    TextField("Correct answer (must match an option)", text: $viewModel.mcCorrectAnswer)
                        .textInputAutocapitalization(.sentences)
                }
        case .question:
            Section(header: Text("Question")) {
                TextField("Enter question", text: $viewModel.qQuestion)
                    .textInputAutocapitalization(.sentences)
            }
            Section(header: Text("Answer (case-insensitive)")) {
                TextField("Enter answer", text: $viewModel.qAnswer)
                    .textInputAutocapitalization(.sentences)
            }
        case .prompt:
            Section(header: Text("Prompt")) {
                TextField("Ex: Name someone you admire", text: $viewModel.promptText)
                    .textInputAutocapitalization(.sentences)
            }
        case nil:
            EmptyView()
        }
    }
}

#Preview {
    CreateChallengeView(challengeType: ChallengeType.question(QuestionData()), challenge: nil) { _ in }
//    CreateChallengeView(challengeType: ChallengeType.prompt(PromptData()), challenge: nil) { _ in }
}

