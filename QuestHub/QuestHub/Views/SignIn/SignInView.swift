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
    @State private var isSigningInWithApple = false
    @State private var navigateToOrganizer = false
    @State private var signInError: String?

    private let appleSignInManager = AppleSignInManager()

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("QuestHub")
                    .font(.largeTitle).bold()
                    .multilineTextAlignment(.center)
                Text("Sign in or create an account to get started")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)

            VStack(spacing: 12) {
                NavigationLink {
                    EmailSignInView(isLoginFlow: false)
                        .navigationTitle("Sign Up")
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                        Text("Continue with Email")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                .signInWithAppleButtonStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityLabel("Continue with Apple")
            }
            .padding(.horizontal)

            NavigationLink(isActive: $navigateToOrganizer) {
                OrganizerHubView()
                    .navigationBarBackButtonHidden(true)
            } label: {
                EmptyView()
            }

            NavigationLink {
                EmailSignInView(isLoginFlow: true)
                    .navigationTitle("Log In")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                Text("Log In")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .alert("Sign In Error", isPresented: .constant(signInError != nil)) {
            Button("OK", role: .cancel) { signInError = nil }
        } message: {
            Text(signInError ?? "")
        }
    }
}

#Preview {
    SignInView()
        .environmentObject(QHAuth())
}
