//
//  HomeViewModel.swift
//  Simmr
//

import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var pastedText: String = ""
    @Published private(set) var isGenerating: Bool = false
    @Published var errorMessage: String?
    @Published private(set) var hasAPIKey: Bool

    private let recipeProvider: RecipeGenerating
    private let apiKeyStore: APIKeyStoring

    init(recipeProvider: RecipeGenerating? = nil, apiKeyStore: APIKeyStoring? = nil) {
        let apiKeyStore = apiKeyStore ?? KeychainAPIKeyStore()
        self.apiKeyStore = apiKeyStore
        self.recipeProvider = recipeProvider ?? RecipeParserService(apiKeyStore: apiKeyStore)
        self.hasAPIKey = apiKeyStore.apiKey?.isEmpty == false
    }

    func refreshAPIKeyStatus() {
        hasAPIKey = apiKeyStore.apiKey?.isEmpty == false
    }

    var canGenerate: Bool {
        !pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isGenerating
    }

    func generateRecipe() async -> Recipe? {
        guard canGenerate else { return nil }
        isGenerating = true
        errorMessage = nil
        defer { isGenerating = false }

        do {
            return try await recipeProvider.generateRecipe(from: pastedText)
        } catch let error as LocalizedError {
            errorMessage = error.errorDescription ?? "Couldn't generate a recipe. Please try again."
            return nil
        } catch {
            errorMessage = "Couldn't generate a recipe. Please try again."
            return nil
        }
    }
}
