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
    var onSuccess: (() -> Void)? = nil

    // External bindings so parent can observe values if desired
    @State private var email: String = ""
    @State private var confirmEmail: String = ""
    @State private var password: String = ""
    @State private var displayName: String = ""

    // UI state
    @State private var isSecureEntry: Bool = true
    @State private var errorMessage: String?
    @State private var isSubmitting: Bool = false
    
    @EnvironmentObject var auth: QHAuth

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
            Text(isLoginFlow ? UIStrings.loginWithEmail : UIStrings.createYourAccount)
                .font(.title2).bold()
            Text(isLoginFlow ? UIStrings.loginEnterEmailAndPassword : UIStrings.signInEnterEmailAndPassword)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    var formFields: some View {
        VStack(spacing: 14) {
            // Email
            TextField(UIStrings.email, text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .submitLabel(.next)
                .padding(12)
                .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            // Confirm Email (only for sign up)
            if !isLoginFlow {
                TextField(UIStrings.confirmEmail, text: $confirmEmail)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .submitLabel(.next)
                    .padding(12)
                    .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            // Display Name (only for sign up, required)
            if !isLoginFlow {
                TextField(UIStrings.displayName, text: $displayName)
                    .textContentType(.name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(false)
                    .submitLabel(.next)
                    .padding(12)
                    .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            // Password
            Group {
                if isSecureEntry {
                    SecureField(UIStrings.password, text: $password)
                        .textContentType(isLoginFlow ? .password : .newPassword)
                        .submitLabel(.go)
                } else {
                    TextField(UIStrings.password, text: $password)
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
                Text(isLoginFlow ? UIStrings.login : UIStrings.signUp)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.qhPrimaryBlue)
        .clipShape(.capsule)
        .padding(.top, 8)
    }

    var secondaryHint: some View {
        Group {
            if isLoginFlow {
                Text(UIStrings.loginHint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text(UIStrings.signInHint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    var isFormValid: Bool {
        if isLoginFlow {
            return isValidEmail(email) && !password.isEmpty
        } else {
            return isValidEmail(email) && email == confirmEmail && !password.isEmpty && !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    func submit() {
        errorMessage = nil
        guard isFormValid else {
            if !isValidEmail(email) {
                errorMessage = UIStrings.enterValidEmail
            } else if !isLoginFlow && email != confirmEmail {
                errorMessage = UIStrings.emailNotMatch
            } else if !isLoginFlow && displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errorMessage = UIStrings.enterDisplayName
            } else if password.isEmpty {
                errorMessage = UIStrings.emptyPassword
            }
            return
        }

        isSubmitting = true
        Task { @MainActor in
            let success: Bool
            if isLoginFlow {
                success = await auth.signIn(email: email, password: password)
            } else {
                let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
                success = await auth.signUp(email: email, password: password, displayName: trimmedName)
            }

            if success {
                errorMessage = nil
                onSuccess?()
            } else {
                errorMessage = auth.lastError?.localizedDescription ?? UIStrings.ssww
            }
            isSubmitting = false
        }
    }

    func isValidEmail(_ email: String) -> Bool {
        // Simple email validation
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return email.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
}

#Preview {
    NavigationStack {
        VStack {
            EmailSignInView(isLoginFlow: true, onSuccess: nil)
            Divider().padding()
            EmailSignInView(isLoginFlow: false, onSuccess: nil)
        }
        .padding()
        .environmentObject(QHAuth())
    }
}
