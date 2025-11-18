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

    let existingChallenge: Challenge?
    let challengeType: ChallengeType?
    let completion: (CreateChallengeResult) -> Void

    init(challengeType: ChallengeType?, challenge: Challenge?, completion: @escaping (CreateChallengeResult) -> Void) {
        self._title = State(initialValue: challenge?.title ?? "")
        self._details = State(initialValue: challenge?.details ?? "")
        self.challengeType = challengeType
        self.existingChallenge = challenge
        self.completion = completion
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Title")) {
                    TextField("Ex: Find the red leaf", text: $title)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.next)
                }
                Section(header: Text("Details")) {
                    TextField("Add details or instructions (optional)", text: $details, axis: .vertical)
                        .textInputAutocapitalization(.sentences)
                        .lineLimit(3, reservesSpace: true)
                }
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
                        let challenge = Challenge(
                            id: existingChallenge?.id ?? UUID().uuidString,
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            details: details.trimmingCharacters(in: .whitespacesAndNewlines),
                            points: 30,
                            challengeType: .question(QuestionData(question: "", answer: ""))
                        )
                        completion(.save(challenge))
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    CreateChallengeView(challengeType: ChallengeType.question(QuestionData()), challenge: nil) { _ in }
}
