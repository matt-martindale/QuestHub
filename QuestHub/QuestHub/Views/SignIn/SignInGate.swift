import SwiftUI

struct SignInGate<Content: View>: View {
    @EnvironmentObject private var auth: QHAuth
    @ViewBuilder let content: () -> Content

    @State private var showSignIn: Bool = false
    @State private var presentDelayTask: Task<Void, Never>? = nil
    @State private var hasAppeared = false
    var onCancel: (() -> Void)? = nil

    var body: some View {
        ZStack {
            content()
        }
        .onAppear {
            hasAppeared = true
            updatePresentation()
        }
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
        // Cancel any pending presentation delay when auth state changes
        presentDelayTask?.cancel()
        presentDelayTask = nil

        // If user is already signed in, ensure the sheet is not showing
        guard auth.currentUser == nil else {
            showSignIn = false
            return
        }

        // Only attempt to present after the view has appeared
        guard hasAppeared else { return }

        // Introduce a small delay before presenting to avoid flash on startup
        let delay: UInt64 = 300_000_000 // 0.3 seconds
        presentDelayTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: delay)
            // If still signed out and task wasn't cancelled, present sheet
            if !Task.isCancelled && auth.currentUser == nil {
                showSignIn = true
            }
        }
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
