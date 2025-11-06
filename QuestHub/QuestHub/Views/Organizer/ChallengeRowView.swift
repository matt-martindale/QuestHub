import SwiftUI

struct ChallengeRowView: View {
    let challenge: Challenge
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.title)
                        .font(.body)
                        .foregroundStyle(.primary)
                    if !challenge.details.isEmpty {
                        Text(challenge.details)
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
    ChallengeRowView(challenge: Challenge(title: "Find the turkey", details: "Locate the hidden turkey near the big oak tree.")) {}
}
