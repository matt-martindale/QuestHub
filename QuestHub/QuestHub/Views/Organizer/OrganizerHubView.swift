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
    @State private var isShowingCreateQuestSheet = false
    @State private var selectedQuest: Quest?
    @State private var isShowingEditQuestSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(spacing: 16) {
                    if let user = auth.currentUser {
                        
                        // Empty vs non-empty state
                        if user.quests.isEmpty {
                            VStack(spacing: 8) {
                                Text("\(UIStrings.welcome)\(user.displayName?.isEmpty == false ? user.displayName! : user.email ?? "anonymous")")
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
                                ForEach(user.quests) { quest in
                                    Button {
                                        selectedQuest = quest
                                        isShowingEditQuestSheet = true
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(quest.title ?? "title")
                                                .font(.headline)
                                            Text(quest.creatorDisplayName ?? "anonymous")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .buttonStyle(.plain)
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

                VStack(spacing: 8) {
                    if auth.currentUser != nil {
                        Button {
                            isShowingCreateQuestSheet = true
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
                            guard let user = auth.currentUser else { return }
                            Task { @MainActor in
                                do {
                                    try await auth.firestore.createMockQuest(forUser: user)
                                    _ = try await auth.firestore.fetchQuests(forUserID: user.id)
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
            .sheet(isPresented: $isShowingCreateQuestSheet) {
                CreateQuestView(auth: auth)
            }
            .fullScreenCover(isPresented: $isShowingEditQuestSheet) {
                if let quest = selectedQuest {
                    CreateQuestView(auth: auth, questToEdit: quest)
                }
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
        }
    }
}

#Preview {
    OrganizerHubView()
        .environmentObject(QHAuth())
}
