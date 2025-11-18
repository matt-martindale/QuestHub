import SwiftUI

struct InfoSheetView: View {
    @StateObject var viewModel: InfoSheetViewModel
    var onDone: () -> Void

    init(viewModel: InfoSheetViewModel, onDone: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onDone = onDone
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Spacer()
                Button("Done") { onDone() }
                    .padding()
                    .bold()
            }
            Spacer()
            HStack {
                Text(viewModel.titleText)
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 50)
            Text(viewModel.infoText)
                .padding(.horizontal, 50)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }
}

#Preview {
    Group {
        InfoSheetView(viewModel: InfoSheetViewModel(flow: .password), onDone: {})
        InfoSheetView(viewModel: InfoSheetViewModel(flow: .maxPlayers), onDone: {})
    }
}
