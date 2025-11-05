//
//  SignInView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/4/25.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth

struct SignInView: View {
    @EnvironmentObject var auth: QHAuth
    @Environment(\.colorScheme) private var colorScheme
    @State private var isSigningInWithApple = false
    @State private var navigateToOrganizer = false
    @State private var signInError: String?

    private let appleSignInManager = AppleSignInManager()

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 8) {
                Text(UIStrings.questHub)
                    .font(.largeTitle).bold()
                    .multilineTextAlignment(.center)
                Text(UIStrings.signInToGetStarted)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)

            VStack(spacing: 12) {
                NavigationLink {
                    EmailSignInView(isLoginFlow: false)
                        .navigationTitle(UIStrings.signUp)
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                        Text(UIStrings.signInWithEmail)
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .foregroundColor(.primary)
                    .clipShape(.capsule)
                }

                SignInWithAppleButton(.signIn, onRequest: { request in
                    appleSignInManager.configure(request)
                    isSigningInWithApple = true
                }, onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        Task {
                            do {
                                let (credential, nonce) = try appleSignInManager.extractCredential(from: authorization)
                                try await auth.handleAppleCredential(credential, nonce: nonce)
                                navigateToOrganizer = true
                            } catch {
                                signInError = error.localizedDescription
                            }
                            isSigningInWithApple = false
                        }
                    case .failure(let error):
                        signInError = error.localizedDescription
                        isSigningInWithApple = false
                    }
                })
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .clipShape(.capsule)
                .accessibilityLabel(UIStrings.continueWithApple)
            }
            .padding(.horizontal)

//            NavigationLink(isActive: $navigateToOrganizer) {
//                OrganizerHubView()
//                    .navigationBarBackButtonHidden(true)
//            } label: {
//                EmptyView()
//            }
            
            Text(UIStrings.or)

            NavigationLink {
                EmailSignInView(isLoginFlow: true)
                    .navigationTitle(UIStrings.login)
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                Text(UIStrings.loginWithEmail)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemBackground))
                    .foregroundColor(.primary)
                    .overlay(
                        Capsule()
                            .stroke(Color.qhPrimaryBlue, lineWidth: 4)
                    )
                    .clipShape(.capsule)
            }
            .padding(.horizontal)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .alert(UIStrings.signInError, isPresented: .constant(signInError != nil)) {
            Button(UIStrings.ok, role: .cancel) { signInError = nil }
        } message: {
            Text(signInError ?? "")
        }
    }
}

#Preview {
    SignInView()
        .environmentObject(QHAuth())
}
