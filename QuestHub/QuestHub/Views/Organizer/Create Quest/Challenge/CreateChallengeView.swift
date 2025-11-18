import SwiftUI

enum CreateChallengeResult {
    case save(Challenge)
    case cancel
    case delete
}

struct CreateChallengeView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var details: String

    // Type-specific editable state
    @State private var photoPrompt: String = ""
    @State private var mcQuestion: String = ""
    @State private var mcAnswers: [String] = ["", "", "", ""]
    @State private var mcCorrectAnswer: String = ""
    @State private var qQuestion: String = ""
    @State private var qAnswer: String = ""
    @State private var promptText: String = ""

    let existingChallenge: Challenge?
    let challengeType: ChallengeType?
    let completion: (CreateChallengeResult) -> Void

    init(challengeType: ChallengeType?, challenge: Challenge?, completion: @escaping (CreateChallengeResult) -> Void) {
        self._title = State(initialValue: challenge?.title ?? "")
        self._details = State(initialValue: challenge?.details ?? "")
        self.challengeType = challengeType
        self.existingChallenge = challenge
        self.completion = completion

        switch challengeType {
        case .photo(let data):
            self._photoPrompt = State(initialValue: data.prompt ?? "")
        case .multipleChoice(let data):
            self._mcQuestion = State(initialValue: data.question ?? "")
            self._mcAnswers = State(initialValue: (data.answers ?? []))
            self._mcCorrectAnswer = State(initialValue: data.correctAnswer ?? "")
        case .question(let data):
            self._qQuestion = State(initialValue: data.question ?? "")
            self._qAnswer = State(initialValue: data.answer ?? "")
        case .prompt(let data):
            self._promptText = State(initialValue: data.prompt ?? "")
        case .none:
            break
        }
    }

    var body: some View {
        NavigationStack {
            Text(challengeTypeTitle())
                .font(.title2.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
            Form {
//                Section(header: Text("Title")) {
//                    TextField("Add title", text: $title)
//                        .textInputAutocapitalization(.sentences)
//                        .submitLabel(.next)
//                }
//                Section(header: Text("Details")) {
//                    TextField("Add details or instructions", text: $details, axis: .vertical)
//                        .textInputAutocapitalization(.sentences)
//                        .lineLimit(3, reservesSpace: true)
//                }
                // Type-specific form content
                typeSpecificForm()
                if existingChallenge != nil {
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
            .navigationTitle(existingChallenge == nil ? "New Challenge" : "Edit Challenge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if existingChallenge != nil {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            completion(.cancel)
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let builtType: ChallengeType = {
                            switch challengeType {
                            case .photo:
                                return .photo(PhotoData(prompt: photoPrompt))
                            case .multipleChoice:
                                // Filter out empty answers and ensure unique answers
                                let trimmed = mcAnswers.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                                let answers = trimmed
                                let correct = mcCorrectAnswer
                                return .multipleChoice(MultipleChoiceData(question: mcQuestion, answers: answers.isEmpty ? nil : answers, correctAnswer: correct.isEmpty ? nil : correct))
                            case .question:
                                return .question(QuestionData(question: qQuestion, answer: qAnswer))
                            case .prompt:
                                return .prompt(PromptData(prompt: promptText))
                            case .none:
                                return .question(QuestionData(question: "", answer: ""))
                            }
                        }()
                        let challenge = Challenge(
                            id: existingChallenge?.id ?? UUID().uuidString,
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            details: details.trimmingCharacters(in: .whitespacesAndNewlines),
                            points: 30,
                            challengeType: builtType
                        )
                        completion(.save(challenge))
                        dismiss()
                    }
//                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||  details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    @ViewBuilder
    private func typeSpecificForm() -> some View {
        switch challengeType {
        case .photo:
            Section(header: Text("Photo Options")) {
                TextField("Enter prompt", text: $photoPrompt)
                    .textInputAutocapitalization(.sentences)
            }
        case .multipleChoice:
            Section(header: Text("Multiple Choice")) {
                TextField("Enter question", text: $mcQuestion)
                    .textInputAutocapitalization(.sentences)
                ForEach(mcAnswers.indices, id: \.self) { idx in
                    TextField("Choice \(idx + 1)", text: Binding(
                        get: { idx < mcAnswers.count ? mcAnswers[idx] : "" },
                        set: { newValue in
                            if idx < mcAnswers.count { mcAnswers[idx] = newValue }
                        }
                    ))
                    .textInputAutocapitalization(.sentences)
                }
                Button("Add Choice") {
                    mcAnswers.append("")
                }
                .disabled(mcAnswers.count >= 8)
                TextField("Correct answer (must match one choice)", text: $mcCorrectAnswer)
                    .textInputAutocapitalization(.sentences)
            }
        case .question:
            Section(header: Text("Question")) {
                TextField("Enter question", text: $qQuestion)
                    .textInputAutocapitalization(.sentences)
                TextField("Enter answer", text: $qAnswer)
                    .textInputAutocapitalization(.sentences)
            }
        case .prompt:
            Section(header: Text("Prompt")) {
                TextField("Enter prompt", text: $promptText, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
                    .textInputAutocapitalization(.sentences)
            }
        case nil:
            EmptyView()
        }
    }
    
    private func challengeTypeTitle() -> String {
        switch challengeType {
        case .photo(_):
            "Photo"
        case .multipleChoice(_):
            "Multiple choice"
        case .question(_):
            "Question"
        case .prompt(_):
            "Prompt"
        case nil:
            "Challenge"
        }
    }
    
}

#Preview {
    CreateChallengeView(challengeType: ChallengeType.question(QuestionData()), challenge: nil) { _ in }
}
