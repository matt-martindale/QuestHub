import SwiftUI

struct SettingsSection: View {
    @ObservedObject var viewModel: CreateQuestViewModel
    @Binding var showMaxPlayersInfo: Bool
    @Binding var showPasswordInfo: Bool

    var body: some View {
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
    }
}
