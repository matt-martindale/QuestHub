import SwiftUI

struct ChallengesSection: View {
    @ObservedObject var viewModel: CreateQuestViewModel

    var body: some View {
        Section(header:
                    HStack {
            Text("Challenges")
                .font(.headline)
            Spacer()
            EditButton()
        }) {
            ForEach(viewModel.challenges.indices, id: \.self) { index in
                let challenge = viewModel.challenges[index]
                CreateChallengeRowView(challenge: challenge) {
                    viewModel.beginEditChallenge(at: index)
                }
            }
            .onMove { indices, newOffset in
                viewModel.moveChallenges(from: indices, to: newOffset)
            }

            Button {
                viewModel.beginAddChallenge()
            } label: {
                Label("Add challenge", systemImage: "plus.circle.fill")
                    .foregroundStyle(Color.qhPrimaryBlue)
            }
            .buttonStyle(.plain)
        }
    }
}
