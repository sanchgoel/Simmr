//
//  BackendRecipeService.swift
//  Simmr
//
//  RecipeGenerating conformer for Simmr's Firebase backend. The app sends
//  source text, selected optimizations, and the optional Kitchen Profile;
//  prompt construction and OpenAI access stay server-side.
//

import Foundation

struct BackendRecipeService: RecipeGenerating {
    private let kitchenProfileStore: KitchenProfileStoring
    private let session: URLSession

    init(
        kitchenProfileStore: KitchenProfileStoring = UserDefaultsKitchenProfileStore(),
        session: URLSession = .shared
    ) {
        self.kitchenProfileStore = kitchenProfileStore
        self.session = session
    }

    func generateRecipe(from pastedText: String, options: RecipeOptimizationOptions) async throws -> Recipe {
        let configuration = try BackendConfiguration.current()
        let client = BackendAPIClient(configuration: configuration, session: session)
        let request = GenerateRecipeRequest(
            input: pastedText,
            optimizationOptions: options.apiValues,
            userProfile: currentUserProfile()
        )
        let response: GenerateRecipeResponse = try await client.post(
            path: "v1/recipes/generate",
            body: request
        )
        return response.recipe
    }

    /// Nil when onboarding hasn't been completed, so the prompt's
    /// "userProfile" field is sent as JSON null.
    private func currentUserProfile() -> RecipeUserProfile? {
        guard let profile = kitchenProfileStore.load(), profile.isComplete else { return nil }
        return RecipeUserProfile.build(from: profile.answers)
    }

    private struct GenerateRecipeRequest: Encodable {
        let input: String
        let optimizationOptions: [String]
        let userProfile: RecipeUserProfile?
    }

    private struct GenerateRecipeResponse: Decodable {
        let recipe: Recipe
    }
}

private extension RecipeOptimizationOptions {
    var apiValues: [String] {
        var values: [String] = []
        if contains(.lowerCalories) { values.append("lower_calories") }
        if contains(.higherProtein) { values.append("higher_protein") }
        if contains(.lowerSugar) { values.append("lower_sugar") }
        if contains(.lowCarb) { values.append("low_carb") }
        if contains(.dairyFree) { values.append("dairy_free") }
        if contains(.spicier) { values.append("spicier") }
        if contains(.kidFriendly) { values.append("kid_friendly") }
        return values
    }
}
