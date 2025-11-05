import SwiftUI

struct SignInGate<Content: View>: View {
    @EnvironmentObject private var auth: QHAuth
    @ViewBuilder let content: () -> Content

    @State private var showSignIn: Bool = false

    var body: some View {
        ZStack {
            content()
        }
        .onAppear { updatePresentation() }
        .onChange(of: auth.currentUser) { _ in updatePresentation() }
        .sheet(isPresented: $showSignIn) {
            SignInView()
                .environmentObject(auth)
                .presentationDetents([.medium, .large])
                .interactiveDismissDisabled(true)
        }
    }

    private func updatePresentation() {
        showSignIn = (auth.currentUser == nil)
    }
}

extension View {
    // Convenience wrapper to gate any view content with sign-in.
    func gatedBySignIn() -> some View {
        SignInGate { self }
    }
}
