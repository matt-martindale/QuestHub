//
//  QHImagePicker.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/12/25.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct SelectedPhoto: Transferable {
    let uiImage: UIImage
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            guard let image = UIImage(data: data) else {
                throw NSError(domain: "QHImagePicker", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to decode image data."])
            }
            return SelectedPhoto(uiImage: image, data: data)
        }
    }
}

struct QHImagePicker: View {
    @Binding var selectedPhotoItem: PhotosPickerItem?
    @Binding var selectedImageData: Data?
    @Binding var isCroppingImage: Bool
    @Binding var imageForCropping: UIImage?
    @ObservedObject var viewModel: CreateQuestViewModel
    var initialImageData: Data? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cover Image")
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.secondary.opacity(0.08))

                    if let data = selectedImageData ?? initialImageData, let uiImage = UIImage(data: data) {
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
                do {
                    // Try importing via a Transferable that supports any image content type
                    if let selected = try await newItem.loadTransferable(type: SelectedPhoto.self) {
                        await MainActor.run {
                            self.selectedImageData = selected.data
                            self.imageForCropping = selected.uiImage
                            self.isCroppingImage = true
                        }
                        return
                    }

                    // Fallback: attempt raw Data and decode
                    if let data = try await newItem.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            self.selectedImageData = data
                            if let uiImage = UIImage(data: data) {
                                self.imageForCropping = uiImage
                                self.isCroppingImage = true
                            }
                        }
                        return
                    }
                } catch {
                    // Log but do not crash UI; you could surface a user-facing alert if desired
                    print("Failed to load image from PhotosPickerItem: \(error)")
                }
            }
        }
    }
}
