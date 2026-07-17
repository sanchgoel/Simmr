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

    /// The recipe system prompt currently being edited — the saved override
    /// if one exists, otherwise the shipped default.
    @Published var promptInput: String = ""
    @Published private(set) var isPromptOverridden: Bool = false
    @Published private(set) var didSavePrompt: Bool = false

    private let store: APIKeyStoring
    private let promptOverrideStore: PromptOverrideStoring

    init(store: APIKeyStoring? = nil, promptOverrideStore: PromptOverrideStoring? = nil) {
        let store = store ?? KeychainAPIKeyStore()
        self.store = store
        self.apiKeyInput = store.apiKey ?? ""
        self.isSaved = store.apiKey?.isEmpty == false

        let promptOverrideStore = promptOverrideStore ?? UserDefaultsPromptOverrideStore()
        self.promptOverrideStore = promptOverrideStore
        let savedOverride = promptOverrideStore.load()
        self.promptInput = savedOverride ?? RecipeJSONSchema.defaultSystemPrompt
        self.isPromptOverridden = savedOverride != nil
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

    func savePrompt() {
        promptOverrideStore.save(promptInput)
        isPromptOverridden = promptOverrideStore.load() != nil
        didSavePrompt = true
    }

    /// Clears the "Prompt saved" confirmation once the user resumes editing.
    func acknowledgePromptEdit() {
        didSavePrompt = false
    }

    func resetPromptToDefault() {
        promptOverrideStore.save(nil)
        promptInput = RecipeJSONSchema.defaultSystemPrompt
        isPromptOverridden = false
        didSavePrompt = false
    }
}
