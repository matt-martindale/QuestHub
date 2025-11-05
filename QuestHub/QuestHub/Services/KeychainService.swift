import Foundation
import Security

enum KeychainService {
    private static let service = "com.questhub.apple-signin"
    private static let account = "apple-user-identifier"

    static func storeAppleUserIdentifier(_ userID: String) throws {
        let data = Data(userID.utf8)

        let queryDelete: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(queryDelete as CFDictionary)

        let queryAdd: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        let status = SecItemAdd(queryAdd as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.keychainFailed(status) }
    }

    static func fetchAppleUserIdentifier() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data, let str = String(data: data, encoding: .utf8) else { return nil }
        return str
    }
}

enum KeychainError: Error, CustomStringConvertible {
    case keychainFailed(OSStatus)

    var description: String {
        switch self {
        case .keychainFailed(let status):
            if let message = SecCopyErrorMessageString(status, nil) as String? {
                return "Keychain operation failed: (status: \(status)) - \(message)"
            } else {
                return "Keychain operation failed with status: \(status)"
            }
        }
    }
}
