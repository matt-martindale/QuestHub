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

// Lightweight view model local to this file to keep changes scoped
@MainActor
private final class PlayerHubViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var hasJoinedQuests: Bool = false
    @Published var errorMessage: String?

    private var listener: ListenerRegistration?

    deinit {
        listener?.remove()
    }

    var currentUser: User? {
        Auth.auth().currentUser
    }

    func startListeningForUserQuests() {
        listener?.remove()
        errorMessage = nil
        hasJoinedQuests = false

        guard let uid = currentUser?.uid else { return }

        let db = Firestore.firestore()
        isLoading = true
        // Listen to userQuests where userID == uid
        listener = db.collection("userQuests")
            .whereField("userId", isEqualTo: uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.hasJoinedQuests = false
                    return
                }
                let count = snapshot?.documents.count ?? 0
                self.hasJoinedQuests = count > 0
            }
    }
}

struct PlayerHubView: View {
    @StateObject private var viewModel = PlayerHubViewModel()
    @State private var showSignIn = false
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                // Content
                Group {
                    if viewModel.isLoading {
                        ProgressView("Loading your quests…")
                            .padding()
                    } else if let message = viewModel.errorMessage {
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
                    } else if viewModel.currentUser == nil {
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
                    } else if !viewModel.hasJoinedQuests {
                        // Empty state when signed in but no quests joined
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
                    } else {
                        // Placeholder for when the user has joined quests. Replace with real content.
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.seal")
                                .font(.system(size: 48))
                                .foregroundStyle(.green)
                            Text("You're in active quests")
                                .font(.headline)
                            Text("Open a quest from your list or search for more.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 24)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                // Bottom CTA: Search Quest
                NavigationLink(value: "searchQuest") {
                    Text("Search Quest")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .font(.headline)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding([.horizontal, .bottom])
                }
            }
            .navigationTitle("Player Hub")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.currentUser != nil {
                        Menu {
                            Button("Profile", systemImage: "person.crop.circle") {}
                            Button("Sign out", systemImage: "rectangle.portrait.and.arrow.right") {
                                try? Auth.auth().signOut()
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
                if viewModel.currentUser != nil {
                    viewModel.startListeningForUserQuests()
                }
            }
            .onChange(of: viewModel.currentUser?.uid) { _, _ in
                if viewModel.currentUser != nil {
                    viewModel.startListeningForUserQuests()
                }
            }
            .navigationDestination(for: String.self) { value in
                switch value {
                case "searchQuest":
                    // Navigate to your SearchQuestView
                    SearchQuestView()
                default:
                    EmptyView()
                }
            }
            .sheet(isPresented: $showSignIn) {
                // Present your sign-in flow
                SignInView()
            }
        }
    }
}

#Preview {
    PlayerHubView()
}
