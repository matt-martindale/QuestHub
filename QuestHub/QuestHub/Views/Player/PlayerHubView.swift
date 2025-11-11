//
//  PlayerHubView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/10/25.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

struct PlayerHubView: View {
    @EnvironmentObject private var auth: QHAuth
    @StateObject private var viewModel = PlayerHubViewModel()
    @State private var showSignIn = false
    @State private var showAccount = false

    var body: some View {
        NavigationStack {
            VStack {
                // Content
                Group {
                    if viewModel.isLoading {
                        loadingView
                    } else if let message = viewModel.errorMessage {
                        errorView(message: message)
                    } else if auth.currentUser == nil {
                        signedOutView
                    } else if viewModel.joinedQuests.isEmpty {
                        emptyQuestsView
                    } else {
                        questsListView
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                NavigationLink {
                    SearchQuestView()
                } label: {
                    Label("Search Quest", systemImage: "wand.and.stars")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding()
                .buttonStyle(.glass)
                .shadow(color: Color.qhPrimaryBlue.opacity(0.25), radius: 8, x: 0, y: 0)
            }
            .navigationTitle("Player Hub")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if auth.currentUser != nil {
                        Menu {
                            Button("Account", systemImage: "person.fill") {
                                showAccount = true
                            }
                            Button(role: .destructive) {
                                auth.signOut()
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
                if let uid = auth.currentUser?.id {
                    viewModel.startListeningForUserQuests(for: uid)
                } else {
                    viewModel.stopListening()
                }
            }
            .onChange(of: auth.currentUser) { oldValue, newValue in
                if let uid = newValue?.id {
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
        Spacer()
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("You're not signed in")
                .font(.headline)
            Text("Sign in to view and save your quests.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        Spacer()
    }

    @ViewBuilder
    private var emptyQuestsView: some View {
        Spacer()
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
        Spacer()
    }

    @ViewBuilder
    private var questsListView: some View {
        List {
            ForEach(viewModel.joinedQuests) { quest in
                QuestListItemView(quest: quest, isEditable: false)
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
        .scrollIndicators(.hidden)
        .overlay(alignment: .center) {
            if auth.isLoadingCreatedQuests {
                ZStack {
                    Color.clear
                    ProgressView("Loading quests…")
                }
            }
        }
        .contentMargins(.bottom, 150)
    }
}

#Preview {
    PlayerHubView()
        .environmentObject(QHAuth())
}
