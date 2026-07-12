//
//  RecipeGenerating.swift
//  Simmr
//
//  Abstraction over "turn pasted text into a Recipe". MockRecipeProvider is
//  the only conformer today; swapping in an AI-backed parser later means
//  writing a new conformer and changing one line at the call site.
//

import Foundation

protocol RecipeGenerating {
    func generateRecipe(from pastedText: String) async throws -> Recipe
}

enum RecipeGeneratingError: Error {
    case missingMockData
    case decodingFailed
}

struct MockRecipeProvider: RecipeGenerating {
    /// Ignores `pastedText` for now and returns a bundled mock recipe after
    /// a short simulated delay so the loading state is visible.
    func generateRecipe(from pastedText: String) async throws -> Recipe {
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
