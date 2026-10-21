import Foundation
import Security

final class SystemCredentialsStore: CredentialsStore {
    private let defaults: UserDefaults
    private let service = "\(Bundle.main.bundleIdentifier ?? "jiachang").credentials.v2"
    private let account = "mealie-password"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> Credentials {
        let migratedPassword = defaults.string(forKey: "password")
        if let migratedPassword, !migratedPassword.isEmpty, keychainPassword() == nil {
            savePassword(migratedPassword)
            defaults.removeObject(forKey: "password")
        }
        return Credentials(
            server: defaults.string(forKey: "baseURL") ?? "",
            username: defaults.string(forKey: "username") ?? "",
            password: keychainPassword() ?? migratedPassword ?? ""
        )
    }

    func save(_ credentials: Credentials) {
        defaults.set(credentials.server, forKey: "baseURL")
        defaults.set(credentials.username, forKey: "username")
        savePassword(credentials.password)
    }

    private func keychainPassword() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func savePassword(_ password: String) {
        let key: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let value = password.data(using: .utf8) ?? Data()
        let status = SecItemUpdate(key as CFDictionary, [kSecValueData as String: value] as CFDictionary)
        if status == errSecItemNotFound {
            var newItem = key
            newItem[kSecValueData as String] = value
            SecItemAdd(newItem as CFDictionary, nil)
        }
    }
}
