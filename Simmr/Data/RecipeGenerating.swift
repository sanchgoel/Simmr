//
//  RecipeGenerating.swift
//  Simmr
//
//  Abstraction over "turn pasted text into a Recipe". BackendRecipeService
//  (OpenAI-backed) is the live conformer; MockRecipeProvider below stays
//  around for SwiftUI Previews and offline development.
//

import Foundation

protocol RecipeGenerating {
    func generateRecipe(from pastedText: String, options: RecipeOptimizationOptions) async throws -> Recipe
}

enum RecipeGeneratingError: Error {
    case missingMockData
    case decodingFailed
}

struct MockRecipeProvider: RecipeGenerating {
    /// Ignores `pastedText` and `options` for now and returns a bundled mock
    /// recipe after a short simulated delay so the loading state is visible.
    func generateRecipe(from pastedText: String, options: RecipeOptimizationOptions) async throws -> Recipe {
        try await Task.sleep(nanoseconds: 500_000_000)

        guard let url = Bundle.main.url(forResource: "mock_recipe", withExtension: "json") else {
            throw RecipeGeneratingError.missingMockData
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(Recipe.self, from: data)
        } catch {
            throw RecipeGeneratingError.decodingFailed
        }
    }
}
