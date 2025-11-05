import Foundation
import AuthenticationServices
import FirebaseAuth

protocol AuthServicing {
    @MainActor
    func signInWithApple(credential: ASAuthorizationAppleIDCredential, nonce: String) async throws
}

enum SignInWithAppleError: Error {
    case credentialRevoked
}

final class AuthService: AuthServicing {
    static let shared = AuthService()
    private init() {}

    @MainActor
    func signInWithApple(credential: ASAuthorizationAppleIDCredential, nonce: String) async throws {
        // Validate credential state
        let userID = credential.user
//        let provider = ASAuthorizationAppleIDProvider()
//        let state = try await provider.credentialState(forUserID: userID)
//        switch state {
//        case .authorized, .transferred:
//            break
//        case .revoked:
//            throw SignInWithAppleError.credentialRevoked
//        case .notFound:
//            break
//        @unknown default:
//            break
//        }

        // Identity token
        guard let identityTokenData = credential.identityToken,
              let idTokenString = String(data: identityTokenData, encoding: .utf8) else {
            throw NSError(domain: "SignInWithApple", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing Apple identity token."])
        }

        // Firebase credential with nonce
        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: credential.fullName
        )

        // Firebase sign in
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Auth.auth().signIn(with: firebaseCredential) { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }

        // Persist Apple user ID
        try KeychainService.storeAppleUserIdentifier(userID)
    }
}
