import SwiftUI
import PhotosUI

struct QuestInfoSection: View {
    @ObservedObject var viewModel: CreateQuestViewModel
    @Binding var selectedPhotoItem: PhotosPickerItem?
    @Binding var selectedImageData: Data?
    @Binding var didDiscardInitialImage: Bool
    let initialCoverImageData: Data?
    @Binding var croppingImage: CroppingImage?

    var body: some View {
        Section {
            QHImagePicker(
                selectedPhotoItem: $selectedPhotoItem,
                selectedImageData: $selectedImageData,
                isCroppingImage: .constant(false),
                imageForCropping: Binding<UIImage?>(
                    get: { nil },
                    set: { newValue in
                        if let img = newValue { self.croppingImage = CroppingImage(image: img) }
                    }
                ),
                viewModel: viewModel,
                initialImageData: didDiscardInitialImage ? nil : initialCoverImageData
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
    }
}
