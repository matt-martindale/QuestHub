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
    @State private var showCreationSuccessAlert = false
    @State private var showAccount = false
    @State private var createdQuest: Quest?
    
    private var isUserSignedIn: Bool { auth.currentUser != nil }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(spacing: 16) {
                    if auth.isLoadingCreatedQuests {
                        loadingView
                    }

                    if let user = auth.currentUser {
                        let display = (user.displayName?.isEmpty == false ? user.displayName! : (user.email ?? "anonymous"))
                        if auth.createdQuests.isEmpty {
                            if !auth.isLoadingCreatedQuests {
                                emptyStateView(for: display)
                            }
                        } else {
                            createdQuestsList
                        }
                    } else {
                        Text(UIStrings.noUserSignedIn)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                createButtonArea
            }
            .onAppear {
                Task {
                    await refreshQuests()
                }
            }
            .sheet(isPresented: $isShowingCreateQuestSheet) {
                CreateQuestView(auth: auth, onCreateSuccess: { quest in
                    createdQuest = quest
                    Task { await refreshQuests() }
                    showCreationSuccessAlert = true
                })
            }
            .sheet(isPresented: $isShowingEditQuestSheet) {
                if let quest = selectedQuest {
                    CreateQuestView(auth: auth, questToEdit: quest)
                }
            }
            .sheet(isPresented: $showAccount) {
                NavigationStack {
                    AccountView()
                }
            }
            .onChange(of: isShowingEditQuestSheet) { oldValue, newValue in
                if oldValue == true && newValue == false {
                    Task { await refreshQuests() }
                }
            }
            .alert("Quest created!", isPresented: $showCreationSuccessAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                let code: String = createdQuest?.questCode ?? "-"
                let passwordText: String = createdQuest?.password?.isEmpty == true ? "" : " and\npassword: '\(createdQuest?.password ?? "-")'"
                Text("Invite players to join by sharing the Quest code: '\(code)'\(passwordText).")
            }
            .navigationTitle(UIStrings.organizerHub)
            .toolbar { organizerToolbar }
        }
    }
    
    @ToolbarContentBuilder
    private var organizerToolbar: some ToolbarContent {
        if isUserSignedIn {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button() {
                        showAccount = true
                    } label: {
                        Label {
                            Text(UIStrings.account)
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
                    HStack() {
                        ZStack {
                            Image(systemName: "person.crop.circle")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var loadingView: some View {
        ProgressView("Loading quests…")
            .padding(.top, 16)
    }

    @ViewBuilder
    private func emptyStateView(for userDisplay: String) -> some View {
        VStack(spacing: 8) {
            Text("\(UIStrings.welcome)\(userDisplay)")
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

    @ViewBuilder
    private var createButtonArea: some View {
        VStack(spacing: 8) {
            if isUserSignedIn {
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
                .shadow(color: Color.qhPrimaryBlue.opacity(0.25), radius: 8, x: 0, y: 0)
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }

    @ViewBuilder
    private var createdQuestsList: some View {
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
        .overlay(alignment: .center) {
            if auth.isLoadingCreatedQuests {
                ZStack {
                    Color.clear
                    ProgressView("Loading quests…")
                }
            }
        }
        .contentMargins(.bottom, 150)
        .refreshable { await refreshQuests() }
    }
    
    private func refreshQuests() async {
        _ = await auth.fetchCreatedQuests()
    }
}

#Preview {
    OrganizerHubView()
        .environmentObject(QHAuth())
}

