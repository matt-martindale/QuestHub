import SwiftUI

// A reusable modifier that presents SignInView as a modal whenever the
// user is not authenticated. It automatically dismisses when sign-in completes.
struct RequiresSignIn: ViewModifier {
    let onCancel: (() -> Void)?
    @EnvironmentObject private var auth: QHAuth
    @State private var showSignIn: Bool = false

    func body(content: Content) -> some View {
        content
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
                .presentationDetents([.fraction(0.9), .large], selection: .constant(.large))
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled(true)
                .onDisappear {
                    // If user dismissed without signing in, propagate cancel action
                    if auth.currentUser == nil {
                        onCancel?()
                    }
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
        modifier(RequiresSignIn(onCancel: nil))
    }

    // Variant that lets a parent react to cancellation (e.g., pop navigation)
    func requiresSignIn(onCancel: @escaping () -> Void) -> some View {
        modifier(RequiresSignIn(onCancel: onCancel))
    }
}
