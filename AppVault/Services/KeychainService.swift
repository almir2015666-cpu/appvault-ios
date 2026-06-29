import Foundation
import Security
import CryptoKit

final class KeychainService {
    static let shared = KeychainService()
    private let service = "com.appvault.pins"

    private init() {}

    func savePin(_ pin: String, forGroupId id: UUID) throws {
        let hash = hashPin(pin, salt: id.uuidString)
        let data = Data(hash.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: id.uuidString,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            throw KeychainError.saveFailed(status)
        }
    }

    func verifyPin(_ pin: String, forGroupId id: UUID) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: id.uuidString,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let storedHash = String(data: data, encoding: .utf8)
        else { return false }

        let inputHash = hashPin(pin, salt: id.uuidString)
        return inputHash == storedHash
    }

    func deletePin(forGroupId id: UUID) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: id.uuidString,
        ]
        SecItemDelete(query as CFDictionary)
    }

    private func hashPin(_ pin: String, salt: String) -> String {
        let input = Data((pin + salt + "appvault_secret").utf8)
        let hash = SHA256.hash(data: input)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    enum KeychainError: Error {
        case saveFailed(OSStatus)
    }
}
