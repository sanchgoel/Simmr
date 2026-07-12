//
//  APIKeySettingsViewModel.swift
//  Simmr
//

import Combine
import Foundation

@MainActor
final class APIKeySettingsViewModel: ObservableObject {
    @Published var apiKeyInput: String = ""
    @Published private(set) var isSaved: Bool = false
    @Published var errorMessage: String?

    private let store: APIKeyStoring

    init(store: APIKeyStoring? = nil) {
        let store = store ?? KeychainAPIKeyStore()
        self.store = store
        self.apiKeyInput = store.apiKey ?? ""
        self.isSaved = store.apiKey?.isEmpty == false
    }

    var canSave: Bool {
        !apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func save() {
        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            try store.save(apiKey: trimmed)
            isSaved = true
            errorMessage = nil
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Couldn't save the API key. Please try again."
        }
    }

    func clear() {
        try? store.clear()
        apiKeyInput = ""
        isSaved = false
    }
}
