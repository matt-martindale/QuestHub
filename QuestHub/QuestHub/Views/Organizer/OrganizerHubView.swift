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
    @State private var initialCoverImageData: Data?
    
    private var isUserSignedIn: Bool { auth.currentUser != nil }
    
    var body: some View {
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
                        createdQuestsCards
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
        .fullScreenCover(isPresented: $isShowingCreateQuestSheet) {
            CreateQuestView(auth: auth, onCreateSuccess: { quest in
                createdQuest = quest
                Task { await refreshQuests() }
                showCreationSuccessAlert = true
            })
        }
        .fullScreenCover(isPresented: $isShowingEditQuestSheet) {
            if let quest = selectedQuest {
                CreateQuestView(auth: auth, questToEdit: quest, initialCoverImageData: initialCoverImageData)
            }
        }
        .sheet(isPresented: $showAccount) {
            NavigationStack {
                AccountView()
            }
        }
        .onChange(of: isShowingEditQuestSheet) { oldValue, newValue in
            if oldValue == true && newValue == false {
                initialCoverImageData = nil
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
    private var createdQuestsCards: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(auth.createdQuests) { quest in
                    NavigationLink(destination: PlayQuestView(quest: quest)) {
                        QuestListItemView(quest: quest) {
                            selectedQuest = quest
                            initialCoverImageData = nil
                            Task {
                                if let urlString = quest.imageURL, let url = URL(string: urlString) {
                                    do {
                                        let (data, _) = try await URLSession.shared.data(from: url)
                                        await MainActor.run { initialCoverImageData = data }
                                    } catch {
                                        // Ignore download errors; proceed without initial image data
                                    }
                                }
                                await MainActor.run { isShowingEditQuestSheet = true }
                            }
                        }
                        .contentShape(Rectangle())
                        .padding(16)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
                        .glassEffect(in: .rect(cornerRadius: 20))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 150)
        }
        .scrollIndicators(.hidden)
        .overlay(alignment: .center) {
            if auth.isLoadingCreatedQuests {
                ZStack {
                    Color.clear
                    ProgressView("Loading quests…")
                }
            }
        }
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
