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

    private let recipeProvider: RecipeGenerating

    init(recipeProvider: RecipeGenerating? = nil) {
        self.recipeProvider = recipeProvider ?? MockRecipeProvider()
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
        } catch {
            errorMessage = "Couldn't generate a recipe. Please try again."
            return nil
        }
    }
}
