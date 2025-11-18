import SwiftUI

struct ChallengeRowView: View {
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
}

#Preview {
    ChallengeRowView(challenge: Challenge(id: "id", title: "Not completed", details: "", points: 5, completed: false)) {}
    ChallengeRowView(challenge: Challenge(id: "id", title: "Completed", details: "Details", points: 10, completed: true)) {}
}
