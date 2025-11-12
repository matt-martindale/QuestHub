//
//  SearchQuestResultsView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/11/25.
//

import SwiftUI

struct SearchQuestResultsView: View {
    // Keep the view model as a StateObject so we own its lifecycle
    @StateObject private var viewModel: SearchQuestResultsViewModel
    @State private var showSignIn = false
    @State private var showAccount = false

    // Initialize with dependencies; the view model will expose needed state
    init(auth: QHAuth, quest: Quest) {
        _viewModel = StateObject(wrappedValue: SearchQuestResultsViewModel(auth: auth, quest: quest))
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Content
                Group {
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.foundQuest == nil {
                        emptyQuestsView
                    } else {
                        questsListView
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .navigationTitle("Found quest!")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.auth.currentUser != nil {
                        Menu {
                            Button("Account", systemImage: "person.fill") {
                                showAccount = true
                            }
                            Button(role: .destructive) {
                                viewModel.auth.signOut()
                            } label: {
                                Label(UIStrings.signOut, systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        } label: {
                            Image(systemName: "person.crop.circle")
                        }
                    } else {
                        Button("Sign in") {
                            showSignIn = true
                        }
                    }
                }
            }
            .onAppear {
                if let uid = viewModel.auth.currentUser?.id {
                    viewModel.startListeningForUserQuests(for: uid)
                } else {
                    viewModel.stopListening()
                }
            }
            .onChange(of: viewModel.auth.currentUser) { _, newUser in
                if let uid = newUser?.id {
                    viewModel.startListeningForUserQuests(for: uid)
                } else {
                    viewModel.stopListening()
                }
            }
            .sheet(isPresented: $showSignIn) {
                NavigationStack {
                    SignInView()
                }
            }
            .sheet(isPresented: $showAccount) {
                NavigationStack {
                    AccountView()
                }
            }
        }
        .alert(item: $viewModel.alertMessage) { msg in
            Alert(title: Text("Unable to join Quest"), message: Text(msg.text), dismissButton: .default(Text("OK")))
        }
    }

    // MARK: - Subviews to help the compiler
    @ViewBuilder
    private var loadingView: some View {
        ProgressView("Loading your quests…")
            .padding()
    }

    @ViewBuilder
    private func errorView(message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 44))
                .foregroundStyle(.orange)
            Text("Couldn't load your quests")
                .font(.headline)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    @ViewBuilder
    private var signedOutView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("You're not signed in")
                .font(.headline)
            Text("Sign in to view and manage your quests.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var emptyQuestsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("No quests yet")
                .font(.title3).bold()
            Text("Tap ‘Search Quest’ below to find and join a game.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 32)
    }

    @ViewBuilder
    private var questsListView: some View {
        VStack {
            if let quest = viewModel.foundQuest {
                QuestListItemView(quest: quest, isEditable: false, hidePassword: true)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 16)
                    .padding(.horizontal, 12)
                    .glassEffect(in: .rect(cornerRadius: 20))
                    .listRowBackground(Color.clear)
                    .padding()
            }
            
            if let message = viewModel.errorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding([.horizontal, .bottom])
            }
            
            if viewModel.requiresPassword() {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Quest password", text: $viewModel.inputPassword)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    Text("Enter the quest password to enable Join.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }

            Button {
                viewModel.joinQuest()
            } label: {
                Label("Join", systemImage: "wand.and.stars")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding()
            .buttonStyle(.glass)
            .shadow(color: Color.qhPrimaryBlue.opacity(0.25), radius: 8, x: 0, y: 0)
        }
    }
}

#if DEBUG
#Preview {
    let auth = QHAuth()
    let quest = Quest(id: "id", questCode: "ABC123", title: "Title", subtitle: "Subtitle", description: "Description", maxPlayers: 100, playersCount: 20, challenges: nil, createdAt: Date(), updatedAt: Date(), creatorID: "creatorID", creatorDisplayName: "Creator Displayname", status: .active, password: "password", requireSignIn: true)
    return SearchQuestResultsView(auth: auth, quest: quest)
        .environmentObject(auth)
}
#endif

