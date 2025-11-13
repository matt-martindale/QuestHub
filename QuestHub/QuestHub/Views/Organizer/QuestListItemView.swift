import SwiftUI

struct QuestListItemView: View {
    let quest: Quest
    var isEditable: Bool = true
    var hidePassword: Bool = false
    var onEdit: () -> Void = {}

    var body: some View {
        HStack {
            // Title stack
            VStack(alignment: .leading, spacing: 4) {
                if let urlString = quest.imageURL, let url = URL(string: urlString), !urlString.isEmpty {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.secondary.opacity(0.1))
                                ProgressView()
                            }
                            .frame(maxWidth: .infinity)
                            .aspectRatio(16/9, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .aspectRatio(16/9, contentMode: .fit) // maintain ratio within width
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                        case .failure:
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondary.opacity(0.1))
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundStyle(.secondary)
                                )
                                .frame(maxWidth: .infinity)
                                .aspectRatio(16/9, contentMode: .fit)

                        @unknown default:
                            EmptyView()
                        }
                    }
                    .padding(.bottom)
                }
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
                            Text(quest.questCode ?? "")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    
                    HStack {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Text("\(quest.playersCount ?? 0)/\(quest.maxPlayers ?? 1) players")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let password = quest.password, !password.isEmpty, !hidePassword {
                            Text("Password:")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(password)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        } else if hidePassword && !(quest.password ?? "").isEmpty {
                            Text("Password required")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Image(systemName: "lock.fill")
                                .font(.subheadline)
                                .foregroundStyle(Color.qhPrimaryRed)
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
                    case .some(.paused):
                        Text("Quest is paused")
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
                    if isEditable {
                        Button(action: onEdit) {
                            Text("Edit")
                                .padding(.horizontal, 8)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Edit quest")
                    }
                }
                .padding(.vertical, 8)
            }
            Spacer()
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    QuestListItemView(quest: Quest(id: "", questCode: "ABC12", title: "Thanksgiving scavenger hunt", subtitle: "subtitle", description: "description", maxPlayers: 50, challenges: [], createdAt: Date(), updatedAt: Date(), creatorID: "u1", creatorDisplayName: "Alice", status: .active, password: "password")){}
        .padding()
}

