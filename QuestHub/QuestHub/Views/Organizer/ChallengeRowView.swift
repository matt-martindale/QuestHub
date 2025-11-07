import SwiftUI

struct ChallengeRowView: View {
    let challenge: Challenge
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .firstTextBaseline) {
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
}

//#Preview {
//    ChallengeRowView(challenge: Challenge(title: "Thanksgiving hunt", details: "Find the turkey", points: 30, challengeType: .question(QuestionData(prompt: "What is your name", answer: "Matt")))) {}
//}
