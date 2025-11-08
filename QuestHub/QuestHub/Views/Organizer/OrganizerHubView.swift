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
    
    private func refreshQuests() async {
        _ = await auth.fetchCreatedQuests()
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(spacing: 16) {
                    if auth.isLoadingCreatedQuests {
                        ProgressView("Loading quests…")
                            .padding(.top, 16)
                    }
                    if let user = auth.currentUser {
                        
                        // Empty vs non-empty state
                        if auth.createdQuests.isEmpty {
                            if !auth.isLoadingCreatedQuests {
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
                            }
                        } else {
                            List {
                                ForEach(auth.createdQuests) { quest in
                                    QuestListItemView(quest: quest) {
                                        selectedQuest = quest
                                        isShowingEditQuestSheet = true
                                    }
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets())
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 12)
                                    .glassEffect(in: .rect(cornerRadius: 20))
                                    .listRowBackground(Color.clear)
                                }
                            }
                            .listStyle(.plain)
                            .contentMargins(.horizontal, 16)
                            .listRowSpacing(16)
                            .scrollContentBackground(.hidden)
                            .overlay {
                                if auth.isLoadingCreatedQuests {
                                    ZStack {
                                        Color.clear
                                        ProgressView("Loading quests…")
                                    }
                                }
                            }
                            // Allow the list to extend under the bottom buttons
                            .contentMargins(.bottom, 150)
                            .refreshable {
                                await refreshQuests()
                            }
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
                            Label("Create Quest", systemImage: "wand.and.stars")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.glass)
                        .shadow(color: Color.qhPrimaryBlue.opacity(0.25), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .onAppear {
                Task {
                    await refreshQuests()
                }
            }
            .sheet(isPresented: $isShowingCreateQuestSheet) {
                CreateQuestView(auth: auth)
            }
            .sheet(isPresented: $isShowingEditQuestSheet) {
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
                                Label {
                                    Text(auth.currentUser?.id ?? UIStrings.account)
                                } icon: {
                                    Image(systemName: "person.fill")
                                }
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
