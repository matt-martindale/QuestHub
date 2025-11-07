//
//  CreateQuestView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/5/25.
//

import SwiftUI
import Combine

struct CreateQuestView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CreateQuestViewModel
    @State private var showMaxPlayersInfo: Bool = false
    @State private var showPasswordInfo: Bool = false

    init(auth: QHAuth, questToEdit: Quest? = nil) {
        _viewModel = StateObject(wrappedValue: CreateQuestViewModel(auth: auth, questToEdit: questToEdit))
    }

    var body: some View {
        NavigationStack {
            List {
                // Section 1 — Quest info
                Section {
                    VStack(alignment: .leading) {
                        Text("Title")
                        TextField("Ex: Thanksgiving scavenger hunt", text: $viewModel.title)
                            .textInputAutocapitalization(.sentences)
                            .submitLabel(.next)
                            .padding(12)
                            .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Subtitle")
                        TextField("(optional)", text: $viewModel.subtitle)
                            .textInputAutocapitalization(.sentences)
                            .submitLabel(.next)
                            .padding(12)
                            .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Description")
                        ZStack(alignment: .topLeading) {
                            if viewModel.descriptionText.isEmpty {
                                Text("Add more details about your quest here.")
                                    .foregroundStyle(.tertiary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                            }
                            TextEditor(text: $viewModel.descriptionText)
                                .textInputAutocapitalization(.sentences)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                        }
                        .frame(minHeight: 120)
                        .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
                .listRowSeparator(.hidden)

                // Section 2 — Challenges
                Section(header:
                            HStack {
                    Text("Challenges")
                        .font(.headline)
                    Spacer()
                    EditButton()
                }) {
                    ForEach(viewModel.challenges.indices, id: \.self) { index in
                        let challenge = viewModel.challenges[index]
                        ChallengeRowView(challenge: challenge) {
                            viewModel.beginEditChallenge(at: index)
                        }
                    }
                    .onMove { indices, newOffset in
                        viewModel.moveChallenges(from: indices, to: newOffset)
                    }
                    
                    Button {
                        viewModel.beginAddChallenge()
                    } label: {
                        Label("Add challenge", systemImage: "plus.circle.fill")
                            .foregroundStyle(Color.qhPrimaryBlue)
                    }
                    .buttonStyle(.plain)
                }

                // Section 3 — Password
                Section(header:
                            HStack {
                    Text("Settings")
                        .font(.headline)
                }) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Text("Max players")
                            Button {
                                showMaxPlayersInfo = true
                            } label: {
                                Image(systemName: "questionmark.circle")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Learn how max players affects your quest.")
                        }
                        .padding(.bottom, 6)
                        Picker("Max players", selection: $viewModel.maxPlayers) {
                            Text("1–10").tag(0)
                            Text("11–100").tag(1)
                            Text("100+").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .sheet(isPresented: $showMaxPlayersInfo) {
                            InfoSheetView(viewModel: InfoSheetViewModel(flow: .maxPlayers)) { showMaxPlayersInfo = false }
                                .presentationDetents([.medium])
                                .presentationDragIndicator(.visible)
                        }
                    }
                    .padding(.top, 4)
                    
                    Toggle(isOn: $viewModel.isPasswordProtected) {
                        HStack(spacing: 6) {
                            Text("Password protect this quest")
                            Button {
                                showPasswordInfo = true
                            } label: {
                                Image(systemName: "questionmark.circle")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("When enabled, players must enter this password to join your quest.")
                            .sheet(isPresented: $showPasswordInfo) {
                                InfoSheetView(viewModel: InfoSheetViewModel(flow: .password)) { showPasswordInfo = false }
                                    .presentationDetents([.medium])
                                    .presentationDragIndicator(.visible)
                            }
                        }
                    }
                    .padding(.trailing, 12)
                    .toggleStyle(.switch)

                    if viewModel.isPasswordProtected {
                        TextField("Enter a password", text: $viewModel.password)
                            .textInputAutocapitalization(.never)
                            .textContentType(.password)
                            .padding(12)
                            .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                
                Section {
                    HStack {
                        Button {
                            viewModel.saveQuest()
                        } label: {
                            Text("Save Quest")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .padding()
                        .buttonStyle(.glass)
                        .shadow(color: Color.qhPrimaryBlue.opacity(0.25), radius: 4, x: 0, y: 4)
                        
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                
            }
            .listStyle(.insetGrouped)
            .navigationTitle(viewModel.isEditing ? "Edit Quest" : "Create Quest")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if let user = viewModel.auth.currentUser {
                    ToolbarItem(placement: .topBarTrailing) {
                        SignedInUserMenu(user: user, allowSignOut: false)
                    }
                }
            }
            
        }
        .onChange(of: viewModel.didFinishSaving) { _, newValue in
            if newValue { dismiss() }
        }
        .fullScreenCover(isPresented: $viewModel.isPresentingCreateChallenge) {
            let existing = viewModel.editingChallengeIndex.flatMap { viewModel.challenges[$0] }
            CreateChallengeView(challenge: existing) { result in
                viewModel.handleChallengeResult(result)
            }
            .presentationDetents([.medium, .large])
        }
        .interactiveDismissDisabled(true)
    }
}

#Preview {
    let auth = QHAuth()
    return CreateQuestView(auth: auth)
        .environmentObject(auth)
}
