//
//  SignInView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/4/25.
//

import SwiftUI

struct SignInView: View {
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

                // Continue with Apple (placeholder)
                Button(action: {
                    // TODO: Handle Sign in with Apple
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "apple.logo")
                        Text("Continue with Apple")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(.horizontal)

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
    }
}

#Preview {
    SignInView()
}
