import SwiftUI

struct SaveSection: View {
    @ObservedObject var viewModel: CreateQuestViewModel
    @Binding var isSaving: Bool
    @Binding var showDeleteConfirmation: Bool

    var body: some View {
        Section {
            VStack(spacing: 0) {
                Button {
                    isSaving = true
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
}
