import SwiftUI

struct CreateChallengeRowView: View {
    let challenge: Challenge
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(Color.qhPrimaryBlue.opacity(0.6), lineWidth: 2)
                    Text(String(challenge.points ?? 0))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.qhPrimaryBlue)
                }
                .frame(width: 32, height: 32)
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.title ?? "Title missing")
                        .font(.body)
                        .foregroundStyle(.primary)
                    if let details = challenge.details, !details.isEmpty {
                        Text(details)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    private var challengeTypeIcon: String {
        switch challenge.challengeType {
        case .photo: return "camera.fill"
        case .multipleChoice: return "list.bullet.rectangle.portrait.fill"
        case .question: return "questionmark.circle.fill"
        case .prompt: return "text.bubble"
        }
    }

    private var challengeTypeLabel: String {
        switch challenge.challengeType {
        case .photo: return "Photo challenge"
        case .multipleChoice: return "Multiple choice"
        case .question: return "Question"
        case .prompt: return "Prompt"
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        CreateChallengeRowView(
            challenge: Challenge(
                id: "id1",
                title: "Take a photo of a sunset",
                details: "Photo",
                points: 5,
                completed: false,
                challengeType: .photo(PhotoData(imageURL: nil, caption: "Take a pic"))
            )
        ) {}

        CreateChallengeRowView(
            challenge: Challenge(
                id: "id2",
                title: "Capital of Spain",
                details: "Multiple Choice",
                points: 10,
                completed: true,
                challengeType: .multipleChoice(MultipleChoiceData(question: "Pick one", answers: ["A","B","C"], correctAnswer: "B"))
            )
        ) {}

        CreateChallengeRowView(
            challenge: Challenge(
                id: "id3",
                title: "What is 2+2",
                details: "Question",
                points: 7,
                completed: false,
                challengeType: .question(QuestionData(question: "Riddle", answer: "Human"))
            )
        ) {}
        
        CreateChallengeRowView(
            challenge: Challenge(
                id: "id3",
                title: "Who's your favorite person",
                details: "Prompt",
                points: 7,
                completed: false,
                challengeType: .question(QuestionData(question: "Riddle", answer: "Human"))
            )
        ) {}
    }
    .padding()
}
