import SwiftUI

struct SignInGate<Content: View>: View {
    @EnvironmentObject private var auth: QHAuth
    @ViewBuilder let content: () -> Content

    @State private var showSignIn: Bool = false
    var onCancel: (() -> Void)? = nil

    var body: some View {
        ZStack {
            content()
        }
        .onAppear { updatePresentation() }
        .onChange(of: auth.currentUser) {
            updatePresentation()
        }
        .sheet(isPresented: $showSignIn) {
            NavigationStack {
                SignInView()
                    .environmentObject(auth)
                    .navigationTitle(UIStrings.signIn)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(UIStrings.cancel) {
                                showSignIn = false
                                onCancel?()
                            }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
            .interactiveDismissDisabled(false)
            .onDisappear {
                if auth.currentUser == nil {
                    onCancel?()
                }
            }
        }
    }

    private func updatePresentation() {
        showSignIn = (auth.currentUser == nil)
    }
}

extension View {
    // Convenience wrapper to gate any view content with sign-in.
    func gatedBySignIn() -> some View {
        return SignInGate(content: { self }, onCancel: {})
    }

    // Variant with onCancel callback (e.g., to pop navigation)
    func gatedBySignIn(onCancel: @escaping () -> Void) -> some View {
        return SignInGate(content: { self }, onCancel: onCancel)
    }
}
