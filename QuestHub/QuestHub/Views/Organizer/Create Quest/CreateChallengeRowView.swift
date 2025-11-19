import SwiftUI

struct CreateChallengeRowView: View {
    let challenge: Challenge
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.primary.opacity(0.1))
                    Image(systemName: challengeTypeIcon)
                        .font(.title3)
                        .foregroundStyle(Color.qhPrimaryBlue)
                }
                .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.title ?? "Title missing")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    if let details = challenge.details, !details.isEmpty {
                        Text(details)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
                Text(String(challenge.points ?? 0) + " pts")
                    .font(.footnote)
                    .foregroundStyle(.primary)
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
        case .photo: return "camera"
        case .multipleChoice: return "list.bullet.rectangle.portrait"
        case .question: return "questionmark.circle"
        case .prompt: return "square.and.pencil"
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
                challengeType: .photo(PhotoData())
            )
        ) {}

        CreateChallengeRowView(
            challenge: Challenge(
                id: "id2",
                title: "Capital of Spain",
                details: "Multiple Choice",
                points: 10,
                completed: true,
                challengeType: .multipleChoice(MultipleChoiceData())
            )
        ) {}

        CreateChallengeRowView(
            challenge: Challenge(
                id: "id3",
                title: "What is 2+2",
                details: "Question",
                points: 7,
                completed: false,
                challengeType: .question(QuestionData())
            )
        ) {}
        
        CreateChallengeRowView(
            challenge: Challenge(
                id: "id3",
                title: "Who's your favorite person",
                details: "Prompt",
                points: 7,
                completed: false,
                challengeType: .prompt(PromptData())
            )
        ) {}
    }
    .padding()
}
