//
//  CreateQuestView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/5/25.
//

import SwiftUI
import Combine
import PhotosUI

struct CroppingImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct CreateQuestView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CreateQuestViewModel
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var showMaxPlayersInfo: Bool = false
    @State private var showPasswordInfo: Bool = false
    @State private var showRequireSignInInfo: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var croppingImage: CroppingImage? = nil
    private let onCreateSuccess: ((Quest) -> Void)?

    init(auth: QHAuth, questToEdit: Quest? = nil, onCreateSuccess: ((Quest) -> Void)? = nil) {
        self.onCreateSuccess = onCreateSuccess
        _viewModel = StateObject(wrappedValue: CreateQuestViewModel(auth: auth, questToEdit: questToEdit))
    }

    var body: some View {
        NavigationStack {
            List {
                // Section 1 — Quest info
                Section {
                    QHImagePicker(
                        selectedPhotoItem: $selectedPhotoItem,
                        selectedImageData: $selectedImageData,
                        isCroppingImage: .constant(false),
                        imageForCropping: Binding<UIImage?>(
                            get: { nil },
                            set: { newValue in
                                if let img = newValue {
                                    self.croppingImage = CroppingImage(image: img)
                                }
                            }
                        ),
                        viewModel: viewModel
                    )
                    
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
                        Picker("Max players", selection: $viewModel.maxPlayersSelection) {
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
                    
                    Toggle(isOn: $viewModel.requireSignIn) {
                        HStack(spacing: 6) {
                            Text("Require players to sign-in")
                            Button {
                                showRequireSignInInfo = true
                            } label: {
                                Image(systemName: "questionmark.circle")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("When enabled, players must be signed in to join your quest.")
                        }
                    }
                    .padding(.trailing, 12)
                    .toggleStyle(.switch)
                    .sheet(isPresented: $showRequireSignInInfo) {
                        InfoSheetView(viewModel: InfoSheetViewModel(flow: .requireSignIn)) { showRequireSignInInfo = false }
                            .presentationDetents([.medium])
                            .presentationDragIndicator(.visible)
                    }
                    
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
                        }
                    }
                    .listRowSeparator(.hidden, edges: .bottom)
                    .padding(.trailing, 12)
                    .toggleStyle(.switch)
                    .sheet(isPresented: $showPasswordInfo) {
                        InfoSheetView(viewModel: InfoSheetViewModel(flow: .password)) { showPasswordInfo = false }
                            .presentationDetents([.medium])
                            .presentationDragIndicator(.visible)
                    }

                    if viewModel.isPasswordProtected {
                        TextField("Enter a password", text: $viewModel.password)
                            .textInputAutocapitalization(.never)
                            .textContentType(.password)
                            .padding(12)
                            .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .listRowSeparator(.hidden, edges: .top)
                    }
                }
                
                Section {
                    VStack(spacing: 0) {
                        Button {
                            viewModel.saveQuest()
                        } label: {
                            Text("Save Quest")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .disabled(!viewModel.canSave)
                        .buttonStyle(.glass)
                        .tint(viewModel.canSave ? Color.qhPrimaryBlue : .secondary)
                        .background(
                            Group {
                                if viewModel.canSave {
                                    LinearGradient(colors: [Color.qhPrimaryBlue.opacity(0.7), Color.qhPrimaryBlue.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                                } else {
                                    Color.clear
                                }
                            }
                        )
                        .shadow(color: .clear.opacity(0.35), radius: 10, x: 0, y: 2)
                        
                        if viewModel.isEditing {
                            Button {
                                showDeleteConfirmation = true
                            } label: {
                                Text("Delete Quest")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .padding(.vertical)
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
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
            if newValue {
                if viewModel.isEditing == false, let quest = viewModel.lastSavedQuest {
                    onCreateSuccess?(quest)
                }
                dismiss()
            }
        }
        .onChange(of: viewModel.didFinishDeleting) { _, newValue in
            if newValue { dismiss() }
        }
        .fullScreenCover(isPresented: $viewModel.isPresentingCreateChallenge) {
            let existing = viewModel.editingChallengeIndex.flatMap { viewModel.challenges[$0] }
            CreateChallengeView(challenge: existing) { result in
                viewModel.handleChallengeResult(result)
            }
            .presentationDetents([.medium, .large])
        }
        .onChange(of: viewModel.isPasswordProtected) { _, newValue in
            if newValue == false {
                viewModel.password = ""
            }
        }
        .alert("Delete this quest?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                viewModel.deleteQuest()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
        .interactiveDismissDisabled(true)
        .fullScreenCover(item: $croppingImage) { item in
            ImageCropperView(image: item.image, aspectRatio: 16.0/9.0) { cropped in
                if let data = cropped.jpegData(compressionQuality: 0.9) {
                    self.selectedImageData = data
                    self.viewModel.pendingCoverImageData = data
                }
                self.croppingImage = nil
            } onCancel: {
                self.croppingImage = nil
            }
        }
    }
}

#Preview {
    let auth = QHAuth()
    return CreateQuestView(auth: auth)
        .environmentObject(auth)
}

