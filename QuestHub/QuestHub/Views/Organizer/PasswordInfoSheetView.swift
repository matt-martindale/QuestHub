import SwiftUI

struct PasswordInfoSheetView: View {
    var onDone: () -> Void

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
                Text("Password protection")
                    .font(.headline)
                Spacer()
            }
            Text("When enabled, players must enter this password to join your quest. Share the password only with the people you want to participate.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }
}

#Preview {
    PasswordInfoSheetView(onDone: {})
}
