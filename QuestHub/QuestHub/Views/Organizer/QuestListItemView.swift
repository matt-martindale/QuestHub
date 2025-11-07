import SwiftUI

struct QuestListItemView: View {
    let quest: Quest
    let onEdit: () -> Void

    var body: some View {
        HStack {
            // Title stack
            VStack(alignment: .leading, spacing: 4) {
                Text(quest.title ?? "")
                    .font(.title3)
                if let subtitle = quest.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Quest Details stack
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        HStack {
                            Image(systemName: "person.crop.circle")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 3)
                            Text(quest.creatorDisplayName ?? "anonymous")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        HStack {
                            Text("Code:")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(quest.id ?? "")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    
                    HStack {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Text("0/\(quest.maxPlayers ?? 1) players")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let password = quest.password, !password.isEmpty {
                            Text("Password:")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(password)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "calendar")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 3)
                        Text(quest.createdAt?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown date")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    
                }
                .padding(.top)
                
                // Quest status stack
                HStack {
                    switch quest.status {
                    case .some(.inactive):
                        Text("Quest is inactive")
                            .font(.callout)
                        Image(systemName: "pause.circle.fill")
                            .foregroundStyle(.yellow)
                    case .some(.active):
                        Text("Quest is active")
                            .font(.callout)
                        Image(systemName: "bolt.circle.fill")
                            .foregroundStyle(.green)
                    case .some(.locked):
                        Text("Quest is locked")
                            .font(.callout)
                        Image(systemName: "lock.fill")
                            .foregroundStyle(Color.qhPrimaryRed)
                    case .none:
                        EmptyView()
                    }
                    Spacer()
                    Button(action: onEdit) {
                        Text("Edit")
                            .padding(8)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Edit quest")
                }
            }
            Spacer()
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    QuestListItemView(quest: Quest(id: "IDH4HD", title: "Thanksgiving scavenger hunt", subtitle: "subtitle", description: "description", maxPlayers: 50, challenges: [], createdAt: Date(), updatedAt: Date(), creatorID: "u1", creatorDisplayName: "Alice", status: .active, password: "password")){}
        .padding()
}
