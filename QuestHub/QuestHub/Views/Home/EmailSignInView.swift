//
//  EmailSignInView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/4/25.
//

import SwiftUI

struct EmailSignInView: View {
    // If true, show Login (email + password). If false, show Sign Up (email + confirm email + password)
    var isLoginFlow: Bool = true

    // External bindings so parent can observe values if desired
    @State private var email: String = ""
    @State private var confirmEmail: String = ""
    @State private var password: String = ""

    // UI state
    @State private var isSecureEntry: Bool = true
    @State private var errorMessage: String?
    @State private var isSubmitting: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            header

            formFields

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            primaryActionButton
                .disabled(!isFormValid || isSubmitting)

            // Optional secondary guidance
            secondaryHint
        }
        .padding()
        .animation(.default, value: isLoginFlow)
    }
}

private extension EmailSignInView {
    var header: some View {
        VStack(spacing: 6) {
            Text(isLoginFlow ? "Log in with Email" : "Create your account")
                .font(.title2).bold()
            Text(isLoginFlow ? "Enter your email and password to continue." : "Enter your email, confirm it, and choose a password.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    var formFields: some View {
        VStack(spacing: 14) {
            // Email
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .submitLabel(.next)
                .padding(12)
                .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            // Confirm Email (only for sign up)
            if !isLoginFlow {
                TextField("Confirm email", text: $confirmEmail)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .submitLabel(.next)
                    .padding(12)
                    .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            // Password
            Group {
                if isSecureEntry {
                    SecureField("Password", text: $password)
                        .textContentType(isLoginFlow ? .password : .newPassword)
                        .submitLabel(.go)
                } else {
                    TextField("Password", text: $password)
                        .textContentType(isLoginFlow ? .password : .newPassword)
                        .submitLabel(.go)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .padding(12)
            .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(alignment: .trailing) {
                Button(action: { isSecureEntry.toggle() }) {
                    Image(systemName: isSecureEntry ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                }
                .padding(.trailing, 8)
            }
        }
    }

    var primaryActionButton: some View {
        Button(action: submit) {
            HStack {
                if isSubmitting { ProgressView().tint(.white) }
                Text(isLoginFlow ? "Log In" : "Sign Up")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(.accentColor)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.top, 8)
    }

    var secondaryHint: some View {
        Group {
            if isLoginFlow {
                Text("Don't have an account? Sign up on the previous screen.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text("Already have an account? Switch to Log In.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    var isFormValid: Bool {
        if isLoginFlow {
            return isValidEmail(email) && !password.isEmpty
        } else {
            return isValidEmail(email) && email == confirmEmail && !password.isEmpty
        }
    }

    func submit() {
        errorMessage = nil
        guard isFormValid else {
            if !isValidEmail(email) {
                errorMessage = "Please enter a valid email address."
            } else if !isLoginFlow && email != confirmEmail {
                errorMessage = "Email addresses do not match."
            } else if password.isEmpty {
                errorMessage = "Password cannot be empty."
            }
            return
        }

        isSubmitting = true
        // Simulate async submit; replace with your auth call
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isSubmitting = false
            // On success, clear errors (parent can handle navigation)
            errorMessage = nil
        }
    }

    func isValidEmail(_ email: String) -> Bool {
        // Simple email validation
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return email.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
}

#Preview {
    VStack {
        EmailSignInView(isLoginFlow: true)
        Divider().padding()
        EmailSignInView(isLoginFlow: false)
    }
    .padding()
}
