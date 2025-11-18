import SwiftUI
import Combine

final class CreateChallengeViewModel: ObservableObject {
    @Published var title: String
    @Published var details: String

    // Type-specific editable state
    @Published var photoPrompt: String = ""
    @Published var mcQuestion: String = ""
    @Published var mcAnswers: [String] = ["", "", "", ""]
    @Published var mcCorrectAnswer: String = ""
    @Published var qQuestion: String = ""
    @Published var qAnswer: String = ""
    @Published var promptText: String = ""

    let existingChallenge: Challenge?
    let challengeType: ChallengeType?

    init(challengeType: ChallengeType?, challenge: Challenge?) {
        self.title = challenge?.title ?? ""
        self.details = challenge?.details ?? ""
        self.challengeType = challengeType
        self.existingChallenge = challenge

        switch challengeType {
        case .photo(let data):
            self.photoPrompt = data.prompt ?? ""
        case .multipleChoice(let data):
            self.mcQuestion = data.question ?? ""
            self.mcAnswers = data.answers ?? []
            self.mcCorrectAnswer = data.correctAnswer ?? ""
        case .question(let data):
            self.qQuestion = data.question ?? ""
            self.qAnswer = data.answer ?? ""
        case .prompt(let data):
            self.promptText = data.prompt ?? ""
        case .none:
            break
        }
    }

    var navigationTitle: String { existingChallenge == nil ? "New Challenge" : "Edit Challenge" }
    var typeTitle: String {
        switch challengeType {
        case .photo: return "Photo"
        case .multipleChoice: return "Multiple choice"
        case .question: return "Question"
        case .prompt: return "Prompt"
        case nil: return "Challenge"
        }
    }

    func buildChallenge() -> Challenge {
        let builtType: ChallengeType = {
            switch challengeType {
            case .photo:
                return .photo(PhotoData(prompt: photoPrompt))
            case .multipleChoice:
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
        return Challenge(
            id: existingChallenge?.id ?? UUID().uuidString,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            details: details.trimmingCharacters(in: .whitespacesAndNewlines),
            points: 30,
            challengeType: builtType
        )
    }
}

enum CreateChallengeResult {
    case save(Challenge)
    case cancel
    case delete
}

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
//                Section(header: Text("Title")) {
//                    TextField("Add title", text: $viewModel.title)
//                        .textInputAutocapitalization(.sentences)
//                        .submitLabel(.next)
//                }
//                Section(header: Text("Details")) {
//                    TextField("Add details or instructions", text: $viewModel.details, axis: .vertical)
//                        .textInputAutocapitalization(.sentences)
//                        .lineLimit(3, reservesSpace: true)
//                }
                // Type-specific form content
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
//                    .disabled(viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||  viewModel.details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
            Section(header: Text("Answer")) {
                TextField("Enter answer", text: $viewModel.qAnswer)
                    .textInputAutocapitalization(.sentences)
            }
        case .prompt:
            Section(header: Text("Prompt")) {
                TextField("Ex: Name a co-worker you admire", text: $viewModel.promptText)
                    .textInputAutocapitalization(.sentences)
            }
        case nil:
            EmptyView()
        }
    }
}

#Preview {
    CreateChallengeView(challengeType: ChallengeType.question(QuestionData()), challenge: nil) { _ in }
    CreateChallengeView(challengeType: ChallengeType.prompt(PromptData()), challenge: nil) { _ in }
}

