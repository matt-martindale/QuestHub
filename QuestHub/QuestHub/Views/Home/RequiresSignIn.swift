import SwiftUI

// A reusable modifier that presents SignInView as a modal whenever the
// user is not authenticated. It automatically dismisses when sign-in completes.
struct RequiresSignIn: ViewModifier {
    @EnvironmentObject private var auth: QHAuth
    @State private var showSignIn: Bool = false

    func body(content: Content) -> some View {
        content
            .onAppear { updatePresentation() }
            .onChange(of: auth.currentUser) { _ in
                updatePresentation()
            }
            .sheet(isPresented: $showSignIn) {
                // Use a NavigationStack if SignInView expects navigation
                SignInView()
                    .environmentObject(auth)
                    .presentationDetents([.medium, .large])
                    .interactiveDismissDisabled(true)
                    .onDisappear {
                        // Ensure we don't re-present if user signed in
                        updatePresentation()
                    }
            }
    }

    private func updatePresentation() {
        // Present when no current user; hide when signed in
        let shouldShow = (auth.currentUser == nil)
        if showSignIn != shouldShow {
            showSignIn = shouldShow
        }
    }
}

extension View {
    // Apply this to any screen that requires the user to be signed in
    func requiresSignIn() -> some View {
        modifier(RequiresSignIn())
    }
}
