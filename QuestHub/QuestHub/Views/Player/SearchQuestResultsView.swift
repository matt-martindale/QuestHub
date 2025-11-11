//
//  SearchQuestResultsView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/11/25.
//

import SwiftUI

struct SearchQuestResultsView: View {
    @StateObject private var viewModel: SearchQuestResultsViewModel
    @State private var showSignIn = false
    @State private var showAccount = false
    
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
                    } else if let message = viewModel.errorMessage {
                        errorView(message: message)
                    } else if self.quest ==  nil {
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
            .onChange(of: viewModel.auth.currentUser) { newUser in
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
            QuestListItemView(quest: quest!, isEditable: false)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
                .padding(.vertical, 16)
                .padding(.horizontal, 12)
                .glassEffect(in: .rect(cornerRadius: 20))
                .listRowBackground(Color.clear)
                .padding()
            
            Button {
                joinQuest()
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
    
    private func joinQuest() {
        if quest?.requireSignIn == true && auth.currentUser == nil {
            print("Sign in required, please sign-in")
            return
        }
        if !(quest?.password ?? "").isEmpty {
            print("Please enter password")
            return
        }
        print("Joining quest: \(quest?.questCode ?? "none")")
    }
}

#Preview {
    SearchQuestResultsView(quest: Quest(id: "id", questCode: "ABC123", title: "Title", subtitle: "Subtitle", description: "Description", maxPlayers: 100, playersCount: 20, challenges: nil, createdAt: Date(), updatedAt: Date(), creatorID: "creatorID", creatorDisplayName: "Creator Displayname", status: .active, password: "password", requireSignIn: true))
        .environmentObject(QHAuth())
}

