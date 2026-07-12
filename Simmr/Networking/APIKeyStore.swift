//
//  APIKeyStore.swift
//  Simmr
//
//  Keychain-backed storage for the user's own OpenAI API key. Simmr has no
//  backend, so each user brings their own key (entered in Settings) rather
//  than the app embedding a shared secret.
//

import Foundation
import Security

protocol APIKeyStoring {
    var apiKey: String? { get }
    func save(apiKey: String) throws
    func clear() throws
}

final class KeychainAPIKeyStore: APIKeyStoring {
    private let service = "com.inspiredevstudio.Simmr.openai"
    private let account = "openai-api-key"

    var apiKey: String? {
        guard let data = readData() else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func save(apiKey: String) throws {
        let data = Data(apiKey.utf8)
        let query = keychainQuery()
        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandled(status: status)
        }
    }

    func clear() throws {
        let status = SecItemDelete(keychainQuery() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandled(status: status)
        }
    }

    private func readData() -> Data? {
        var query = keychainQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    private func keychainQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}

enum KeychainError: LocalizedError {
    case unhandled(status: OSStatus)

    var errorDescription: String? {
        "Couldn't access the keychain. Please try again."
    }
}
