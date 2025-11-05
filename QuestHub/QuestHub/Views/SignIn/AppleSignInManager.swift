import Foundation
import AuthenticationServices
import CryptoKit
import Security

final class AppleSignInManager {
    private(set) var currentNonce: String?

    func configure(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
        let nonce = NonceGenerator.randomNonceString()
        currentNonce = nonce
        request.nonce = NonceGenerator.sha256(nonce)
    }

    func extractCredential(from authorization: ASAuthorization) throws -> (credential: ASAuthorizationAppleIDCredential, nonce: String) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AppleSignInError.unexpectedCredentialType(type(of: authorization.credential))
        }
        guard let nonce = currentNonce else {
            throw AppleSignInError.missingNonce
        }
        return (appleIDCredential, nonce)
    }
}

enum AppleSignInError: LocalizedError {
    case unexpectedCredentialType(Any.Type)
    case missingNonce

    var errorDescription: String? {
        switch self {
        case .unexpectedCredentialType(let t):
            return "Unexpected credential type: \(t)"
        case .missingNonce:
            return "Missing nonce for Apple sign-in."
        }
    }
}

// MARK: - Nonce utilities
enum NonceGenerator {
    static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            precondition(errorCode == errSecSuccess, "Unable to generate nonce. OSStatus \(errorCode)")
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let digest = SHA256.hash(data: inputData)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
