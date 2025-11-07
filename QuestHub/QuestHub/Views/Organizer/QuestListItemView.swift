import SwiftUI

struct QuestListItemView: View {
    let quest: Quest
    let onEdit: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(quest.title ?? "title")
                    .font(.headline)
                Text(quest.creatorDisplayName ?? "anonymous")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: onEdit) {
                Text("Edit")
                    .padding(8)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Edit quest")
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    QuestListItemView(quest: Quest(id: "demo", title: "Sample Quest", subtitle: "", description: "", challenges: [], createdAt: Date(), updatedAt: Date(), creatorID: "u1", creatorDisplayName: "Alice", isLocked: false, password: nil)) {
        // edit action preview
    }
}
