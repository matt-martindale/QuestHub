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
            ZStack(alignment: .bottom) {
                // Content area (fills and scrolls behind)
                VStack(spacing: 16) {
                    if let user = auth.currentUser {
                        // Empty vs non-empty state
                        if user.quests.isEmpty && quests.isEmpty {
                            VStack(spacing: 8) {
                                Text("\(UIStrings.welcome)\(user.displayName?.isEmpty == false ? user.displayName! : user.email)")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                VStack(spacing: 8) {
                                    Text("You don't have any quests yet.")
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                    Image(systemName: "tray")
                                        .font(.system(size: 80))
                                    Text("Tap the button below to create your first quest.")
                                        .font(.footnote)
                                        .foregroundStyle(.tertiary)
                                }
                                .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .contentShape(Rectangle())
                        } else {
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
                            // Allow the list to extend under the bottom buttons
                            .contentMargins(.bottom, 150)
                        }
                    } else {
                        Text(UIStrings.noUserSignedIn)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                // Bottom action overlay (clear background, floats above content)
                VStack(spacing: 8) {
                    if auth.currentUser != nil {
                        Button {
                            // Navigate to create quest page
                        } label: {
                            Label("Create a Quest", systemImage: "wand.and.stars")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.glass)
                        .shadow(color: Color.qhPrimaryBlue.opacity(0.25), radius: 8, x: 0, y: 4)

                        Button {
                            guard let uid = auth.currentUser?.id else { return }
                            Task { @MainActor in
                                do {
                                    try await auth.firestore.createMockQuest(forUserID: uid)
                                    let latest = try await auth.firestore.fetchQuests(forUserID: uid)
                                    quests = latest
                                } catch {
                                    print("Failed to create mock quest: \(error)")
                                }
                            }
                        } label: {
                            Label("Create Mock Quest", systemImage: "wand.and.stars")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle(UIStrings.organizerHub)
            .toolbar {
                if let _ = auth.currentUser {
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
