import Foundation
import Security

/// Le trousseau, pour la clé d'API et rien d'autre.
///
/// Une clé d'API n'a pas sa place dans `UserDefaults` : elle sort avec les
/// sauvegardes et traîne en clair. Ici elle reste sur l'appareil, et elle n'est
/// jamais écrite dans les journaux ni exportée avec eux.
enum Keychain {

    private static let service = "com.franckmoyal.Shuo"

    static func write(_ value: String?, for account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)

        guard let value, !value.isEmpty, let data = value.data(using: .utf8) else { return }
        var insert = query
        insert[kSecValueData as String] = data
        insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(insert as CFDictionary, nil)
    }

    static func read(_ account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// La clé Anthropic, si elle a été renseignée en mode développeur.
    static var anthropicAPIKey: String? {
        get { read("anthropic-api-key") }
        set { write(newValue, for: "anthropic-api-key") }
    }
}
