import Foundation
import ManagedSettings
import FamilyControls

// Compartilha o conjunto de tokens de um grupo entre o app e a extensão
// DeviceActivityMonitor, via keychain (grupo de acesso do time).
enum SharedShieldStore {
    private static let service = "com.appvault.sharedshield"
    private static let accessGroup = "66U94U6Q5H.com.appvault.app"

    static func saveTokens(_ tokens: Set<ApplicationToken>, groupId: String) {
        guard let data = try? JSONEncoder().encode(tokens) else { return }
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: groupId,
            kSecAttrAccessGroup as String: accessGroup,
        ]
        SecItemDelete(query as CFDictionary)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(query as CFDictionary, nil)
    }

    static func loadTokens(groupId: String) -> Set<ApplicationToken> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: groupId,
            kSecAttrAccessGroup as String: accessGroup,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let tokens = try? JSONDecoder().decode(Set<ApplicationToken>.self, from: data)
        else { return [] }
        return tokens
    }

    static func clearTokens(groupId: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: groupId,
            kSecAttrAccessGroup as String: accessGroup,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
