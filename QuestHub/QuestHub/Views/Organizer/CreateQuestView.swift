//
//  CreateQuestView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/5/25.
//

import SwiftUI
import Combine
import PhotosUI

struct CreateQuestView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CreateQuestViewModel
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var showMaxPlayersInfo: Bool = false
    @State private var showPasswordInfo: Bool = false
    @State private var showRequireSignInInfo: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var isCroppingImage: Bool = false
    @State private var imageForCropping: UIImage? = nil
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
                    CoverImagePicker(selectedPhotoItem: $selectedPhotoItem, selectedImageData: $selectedImageData, isCroppingImage: $isCroppingImage, imageForCropping: $imageForCropping, viewModel: viewModel)
                    
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
        .fullScreenCover(isPresented: $isCroppingImage) {
            if let image = imageForCropping {
                ImageCropperView(image: image, aspectRatio: 16.0/9.0) { cropped in
                    if let data = cropped.jpegData(compressionQuality: 0.9) {
                        self.selectedImageData = data
                        self.viewModel.pendingCoverImageData = data
                    }
                    self.imageForCropping = nil
                } onCancel: {
                    self.imageForCropping = nil
                }
            }
        }
    }
    
    private struct CoverImagePicker: View {
        @Binding var selectedPhotoItem: PhotosPickerItem?
        @Binding var selectedImageData: Data?
        @Binding var isCroppingImage: Bool
        @Binding var imageForCropping: UIImage?
        @ObservedObject var viewModel: CreateQuestViewModel

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Cover Image")
                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.secondary.opacity(0.08))

                        if let data = selectedImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .clipped()
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.system(size: 36))
                                    .foregroundStyle(.secondary)
                                Text("Add a cover image")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(16/9, contentMode: .fit)
                    .padding(.horizontal)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    HStack(spacing: 30) {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text(selectedImageData == nil ? "Add photo" : "Change photo")
                            }
                            .foregroundStyle(Color.qhPrimaryBlue)
                        }
                        .buttonStyle(.plain)

                        if selectedImageData != nil {
                            Button(role: .destructive) {
                                selectedImageData = nil
                                selectedPhotoItem = nil
                                viewModel.pendingCoverImageData = nil
                            } label: {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Remove")
                                }
                                .foregroundStyle(Color.qhPrimaryRed)
                            }
                            .buttonStyle(.borderless)
                        }
                    }

                    Spacer()
                }
                .padding(.vertical, 4)
                Text("This image will represent your quest to players.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            if let uiImage = UIImage(data: data) {
                                self.imageForCropping = uiImage
                                self.isCroppingImage = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    private struct ImageCropperView: View {
        let image: UIImage
        let aspectRatio: CGFloat
        let onCropped: (UIImage) -> Void
        let onCancel: () -> Void

        @Environment(\.dismiss) private var dismiss
        @State private var scale: CGFloat = 1
        @State private var lastScale: CGFloat = 1
        @State private var offset: CGSize = .zero
        @State private var lastOffset: CGSize = .zero
        @State private var minAllowedScale: CGFloat = 1
        @State private var computedMinScale: CGFloat = 1

        var body: some View {
            GeometryReader { geo in
                ZStack {
                    Color.black.ignoresSafeArea()

                    let horizontalPadding: CGFloat = 24
                    let availableWidth = max(0, geo.size.width - horizontalPadding * 2)
                    let cropWidth = min(availableWidth, geo.size.height)
                    let cropHeight = cropWidth / aspectRatio
                    let cropSize = CGSize(width: cropWidth, height: cropHeight)
                    let cropRect = CGRect(
                        x: (geo.size.width - cropSize.width) / 2,
                        y: (geo.size.height - cropSize.height) / 2,
                        width: cropSize.width,
                        height: cropSize.height
                    )

                    let imageAspect = image.size.width / image.size.height
                    let canvasAspect = geo.size.width / geo.size.height

                    let fittedSize: CGSize = {
                        if imageAspect > canvasAspect {
                            let width = geo.size.width
                            let height = width / imageAspect
                            return CGSize(width: width, height: height)
                        } else {
                            let height = geo.size.height
                            let width = height * imageAspect
                            return CGSize(width: width, height: height)
                        }
                    }()

                    let minScaleX = cropRect.width / fittedSize.width
                    let minScaleY = cropRect.height / fittedSize.height
                    let localComputedMinScale = max(minScaleX, minScaleY)
                    let maxScale: CGFloat = max(localComputedMinScale * 4, 4)

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            SimultaneousGesture(
                                DragGesture()
                                    .onChanged { value in
                                        let proposed = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                        offset = clampOffset(
                                            proposed,
                                            imageSize: fittedSize,
                                            cropRect: cropRect,
                                            canvasSize: geo.size,
                                            scale: scale
                                        )
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    },
                                MagnificationGesture()
                                    .onChanged { value in
                                        let proposedScale = lastScale * value
                                        let clamped = min(maxScale, max(localComputedMinScale, proposedScale))
                                        if clamped != scale {
                                            let ratio = clamped / max(scale, 0.0001)
                                            offset = CGSize(width: offset.width * ratio, height: offset.height * ratio)
                                        }
                                        scale = clamped
                                        offset = clampOffset(
                                            offset,
                                            imageSize: fittedSize,
                                            cropRect: cropRect,
                                            canvasSize: geo.size,
                                            scale: scale
                                        )
                                    }
                                    .onEnded { _ in
                                        lastScale = scale
                                        lastOffset = offset
                                    }
                            )
                        )
                        .clipped()

                    Color.black.opacity(0.5)
                        .mask(
                            Rectangle()
                                .fill(style: FillStyle(eoFill: true))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .path(in: cropRect)
                                        .fill(Color.black)
                                )
                        )
                        .allowsHitTesting(false)

                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: cropRect.width, height: cropRect.height)
                        .position(x: cropRect.midX, y: cropRect.midY)

                    VStack {
                        Spacer()
                        HStack {
                            Button("Cancel") { onCancel(); dismiss() }
                            Spacer()
                            Button("Crop") {
                                if let result = renderCroppedImage(canvasSize: geo.size, cropRect: cropRect) {
                                    onCropped(result)
                                }
                                dismiss()
                            }
                        }
                        .padding()
                    }

                    Color.clear
                        .onAppear {
                            let minScale = localComputedMinScale
                            if scale < minScale {
                                scale = minScale
                                lastScale = minScale
                            }
                            offset = clampOffset(offset, imageSize: fittedSize, cropRect: cropRect, canvasSize: geo.size, scale: scale)
                            lastOffset = offset
                        }
                        .onChange(of: localComputedMinScale) { _, newMin in
                            if scale < newMin {
                                scale = newMin
                                lastScale = newMin
                            }
                            offset = clampOffset(offset, imageSize: fittedSize, cropRect: cropRect, canvasSize: geo.size, scale: scale)
                            lastOffset = offset
                        }
                }
            }
        }

        private func renderCroppedImage(canvasSize: CGSize, cropRect: CGRect) -> UIImage? {
            let imageAspect = image.size.width / image.size.height
            let canvasAspect = canvasSize.width / canvasSize.height

            let fittedSize: CGSize = {
                if imageAspect > canvasAspect {
                    let width = canvasSize.width
                    let height = width / imageAspect
                    return CGSize(width: width, height: height)
                } else {
                    let height = canvasSize.height
                    let width = height * imageAspect
                    return CGSize(width: width, height: height)
                }
            }()

            let imageOrigin = CGPoint(x: (canvasSize.width - fittedSize.width) / 2, y: (canvasSize.height - fittedSize.height) / 2)
            let transformedSize = CGSize(width: fittedSize.width * scale, height: fittedSize.height * scale)
            let transformedOrigin = CGPoint(x: imageOrigin.x + offset.width - (transformedSize.width - fittedSize.width) / 2, y: imageOrigin.y + offset.height - (transformedSize.height - fittedSize.height) / 2)

            let scaleX = image.size.width / transformedSize.width
            let scaleY = image.size.height / transformedSize.height

            let xInImage = (cropRect.minX - transformedOrigin.x) * scaleX
            let yInImage = (cropRect.minY - transformedOrigin.y) * scaleY
            let widthInImage = cropRect.width * scaleX
            let heightInImage = cropRect.height * scaleY

            let imageCropRect = CGRect(x: xInImage, y: yInImage, width: widthInImage, height: heightInImage).integral
            guard let cgImage = image.cgImage else { return nil }
            let boundedRect = imageCropRect.intersection(CGRect(origin: .zero, size: image.size))
            guard let cropped = cgImage.cropping(to: boundedRect) else { return nil }
            return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
        }
        
        private func clampOffset(_ proposed: CGSize, imageSize: CGSize, cropRect: CGRect, canvasSize: CGSize, scale: CGFloat) -> CGSize {
            let imageOrigin = CGPoint(
                x: (canvasSize.width - imageSize.width) / 2,
                y: (canvasSize.height - imageSize.height) / 2
            )
            let transformedSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)

            let baseOrigin = CGPoint(
                x: imageOrigin.x - (transformedSize.width - imageSize.width) / 2,
                y: imageOrigin.y - (transformedSize.height - imageSize.height) / 2
            )

            let proposedOrigin = CGPoint(x: baseOrigin.x + proposed.width, y: baseOrigin.y + proposed.height)

            let minX = cropRect.maxX - transformedSize.width
            let maxX = cropRect.minX
            let minY = cropRect.maxY - transformedSize.height
            let maxY = cropRect.minY

            let clampedOriginX = min(max(proposedOrigin.x, minX), maxX)
            let clampedOriginY = min(max(proposedOrigin.y, minY), maxY)

            let clampedOffset = CGSize(
                width: clampedOriginX - baseOrigin.x,
                height: clampedOriginY - baseOrigin.y
            )
            return clampedOffset
        }
    }
}

#Preview {
    let auth = QHAuth()
    return CreateQuestView(auth: auth)
        .environmentObject(auth)
}
