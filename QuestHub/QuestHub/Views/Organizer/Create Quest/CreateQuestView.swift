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
    @State private var didDiscardInitialImage: Bool = false
    private let initialCoverImageData: Data?
    @State private var showMaxPlayersInfo: Bool = false
    @State private var showPasswordInfo: Bool = false
    @State private var showRequireSignInInfo: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var croppingImage: CroppingImage? = nil
    @State private var isSaving: Bool = false
    private let onCreateSuccess: ((Quest) -> Void)?

    init(auth: QHAuth, questToEdit: Quest? = nil, initialCoverImageData: Data? = nil, onCreateSuccess: ((Quest) -> Void)? = nil) {
        self.onCreateSuccess = onCreateSuccess
        self.initialCoverImageData = initialCoverImageData
        _viewModel = StateObject(wrappedValue: CreateQuestViewModel(auth: auth, questToEdit: questToEdit))
    }

    var body: some View {
        NavigationStack {
            contentList
                .navigationTitle(viewModel.isEditing ? "Edit Quest" : "Create Quest")
                .navigationBarTitleDisplayMode(.large)
                .toolbar { toolbarContent }
                .overlay { savingOverlay }
                .disabled(isSaving)
        }
        .onAppear(perform: handleOnAppear)
        .onChange(of: selectedImageData, handleSelectedImageDataChange)
        .onChange(of: viewModel.didFinishSaving, handleDidFinishSavingChange)
        .onChange(of: viewModel.didFinishDeleting) { _, newValue in if newValue { dismiss() } }
        .fullScreenCover(isPresented: $viewModel.isPresentingCreateChallenge) { createChallengeSheet }
        .onChange(of: viewModel.isPasswordProtected) { _, newValue in if newValue == false { viewModel.password = "" } }
        .alert("Delete this quest?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) { viewModel.deleteQuest() }
            Button("Cancel", role: .cancel) { }
        } message: { Text("This action cannot be undone.") }
        .interactiveDismissDisabled(true)
        .fullScreenCover(item: $croppingImage) { item in imageCropper(for: item) }
    }
    
    private var contentList: some View {
        List {
            QuestInfoSection(viewModel: viewModel,
                             selectedPhotoItem: $selectedPhotoItem,
                             selectedImageData: $selectedImageData,
                             didDiscardInitialImage: $didDiscardInitialImage,
                             initialCoverImageData: initialCoverImageData,
                             croppingImage: $croppingImage)

            ChallengesSection(viewModel: viewModel)

            SettingsSection(viewModel: viewModel,
                            showMaxPlayersInfo: $showMaxPlayersInfo,
                            showPasswordInfo: $showPasswordInfo)

            SaveSection(viewModel: viewModel,
                        isSaving: $isSaving,
                        showDeleteConfirmation: $showDeleteConfirmation)
        }
        .listStyle(.insetGrouped)
    }
    
    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }
        if let user = viewModel.auth.currentUser {
            ToolbarItem(placement: .topBarTrailing) {
                SignedInUserMenu(user: user, allowSignOut: false)
            }
        }
    }
    
    @ViewBuilder private var savingOverlay: some View {
        if isSaving {
            ZStack {
                Color.black.opacity(0.1)
                    .ignoresSafeArea()
                VStack(spacing: 12) {
                    ProgressView("Saving…")
                        .progressViewStyle(.circular)
                }
                .padding(24)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
    
    private var createChallengeSheet: some View {
        let existing = viewModel.editingChallengeIndex.flatMap { viewModel.challenges[$0] }
        return CreateChallengeView(challengeType: existing?.challengeType, challenge: existing) { result in
            viewModel.handleChallengeResult(result)
        }
        .presentationDetents([.medium, .large])
    }
    
    private func imageCropper(for item: CroppingImage) -> some View {
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
    
    private func handleOnAppear() {
        if viewModel.isEditing, didDiscardInitialImage == false, selectedImageData == nil, let data = initialCoverImageData {
            self.selectedImageData = data
            self.viewModel.pendingCoverImageData = data
        }
    }
    
    private func handleSelectedImageDataChange(oldValue: Data?, newValue: Data?) {
        if newValue == nil, initialCoverImageData != nil {
            didDiscardInitialImage = true
            viewModel.pendingCoverImageData = nil
        }
    }
    
    private func handleDidFinishSavingChange(oldValue: Bool, newValue: Bool) {
        if newValue {
            isSaving = false
            if viewModel.isEditing == false, let quest = viewModel.lastSavedQuest {
                onCreateSuccess?(quest)
            }
            dismiss()
        }
    }
}

#Preview {
    let auth = QHAuth()
    return CreateQuestView(auth: auth, initialCoverImageData: nil)
        .environmentObject(auth)
}
