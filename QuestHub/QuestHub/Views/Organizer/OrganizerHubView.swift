//
//  OrganizerHubView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/4/25.
//

import SwiftUI

struct OrganizerHubView: View {
    @EnvironmentObject var auth: QHAuth
    @Environment(\.dismiss) private var dismiss
    @State private var quests: [Quest] = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let user = auth.currentUser {
                    Text("\(UIStrings.welcome)\(user.displayName?.isEmpty == false ? user.displayName! : user.email)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("User ID: \(user.id)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Quest ID: \(user.quests.first?.id)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    
                    List {
                        if quests.isEmpty {
                            Text("No quests yet")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(quests) { quest in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(quest.title)
                                        .font(.headline)
                                    if let subtitle = quest.subtitle, !subtitle.isEmpty {
                                        Text(subtitle)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 250)
                    
                    // Add Quest Button
                    Button {
                        // Navigate to create quest page
                    } label: {
                        Label("Create a Quest", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .backgroundStyle(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.glass)
                    
                    // Create Mock Quest button
                    Button {
                        guard let uid = auth.currentUser?.id else { return }
                        Task { @MainActor in
                            do {
                                try await auth.firestore.createMockQuest(forUserID: uid)
                                // Refresh quests and update local state for display
                                let latest = try await auth.firestore.fetchQuests(forUserID: uid)
                                quests = latest
                            } catch {
                                // Optionally handle error UI later
                                print("Failed to create mock quest: \(error)")
                            }
                        }
                    } label: {
                        Label("Create Mock Quest", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Text(UIStrings.noUserSignedIn)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .navigationTitle(UIStrings.organizerHub)
            .toolbar {
                if let user = auth.currentUser {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button() {
                                // Go to Account page
                            } label: {
                                Label(UIStrings.account, systemImage: "person.fill")
                            }
                            Button(role: .destructive) {
                                auth.signOut()
                            } label: {
                                Label(UIStrings.signOut, systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        } label: {
                            HStack(spacing: 8) {
                                ZStack {
                                    Image(systemName: "person.fill")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                                .frame(width: 28, height: 28)
                            }
                            .padding(.vertical, 2)
                            .padding(.horizontal, 6)
                        }
                    }
                }
            }
            .task(id: auth.currentUser?.id) {
                guard let uid = auth.currentUser?.id else { return }
                do {
                    quests = try await auth.firestore.fetchQuests(forUserID: uid)
                } catch {
                    // Optionally handle error UI later
                    print("Failed to fetch quests: \(error)")
                }
            }
        }
    }
}

#Preview {
    OrganizerHubView()
        .environmentObject(QHAuth())
}
