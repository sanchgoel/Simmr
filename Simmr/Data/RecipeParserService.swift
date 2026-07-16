//
//  RecipeParserService.swift
//  Simmr
//
//  RecipeGenerating conformer that turns pasted text into a Recipe via
//  OpenAI Structured Outputs: RecipeParserService -> OpenAIClient -> Recipe.
//  Swapping the input source later (YouTube transcript, OCR, website
//  content) only means changing what text gets passed to generateRecipe —
//  this service and everything downstream of it is unaffected.
//

import Foundation

struct RecipeParserService: RecipeGenerating {
    private let apiKeyStore: APIKeyStoring
    private let model: String

    init(apiKeyStore: APIKeyStoring = KeychainAPIKeyStore(), model: String = "gpt-4.1-mini") {
        self.apiKeyStore = apiKeyStore
        self.model = model
    }

    func generateRecipe(from pastedText: String, options: RecipeOptimizationOptions) async throws -> Recipe {
        guard let apiKey = apiKeyStore.apiKey, !apiKey.isEmpty else {
            throw OpenAIClientError.missingAPIKey
        }

        let client = OpenAIClient(apiKey: apiKey, model: model)
        let data = try await client.createStructuredCompletion(
            systemPrompt: RecipeJSONSchema.systemPrompt,
            userPrompt: Self.userPrompt(pastedText: pastedText, options: options),
            schemaName: RecipeJSONSchema.schemaName,
            schema: RecipeJSONSchema.schema
        )

        do {
            return try JSONDecoder().decode(Recipe.self, from: data)
        } catch {
            throw OpenAIClientError.malformedCompletion
        }
    }

    private static func userPrompt(pastedText: String, options: RecipeOptimizationOptions) -> String {
        var instructions: [String] = []
        if options.contains(.lowerCalories) {
            instructions.append("Reduce overall calories per serving where reasonable (lighter cooking methods, portion-conscious amounts, lower-calorie substitutions) without losing the dish's identity.")
        }
        if options.contains(.higherProtein) {
            instructions.append("Increase the protein content where reasonable (larger protein portions, protein-rich additions or substitutions) while keeping the dish coherent.")
        }
        if options.contains(.lowerSugar) {
            instructions.append("Reduce the sugar content where reasonable (less added sugar, lower-sugar substitutions) while keeping the dish palatable.")
        }
        if options.contains(.lowCarb) {
            instructions.append("Make this recipe lower-carb where reasonable (swap or reduce high-carb ingredients like rice, pasta, bread, or sugar) while keeping the dish coherent.")
        }
        if options.contains(.dairyFree) {
            instructions.append("Make this recipe dairy-free by substituting any dairy ingredients (milk, butter, cheese, cream, yogurt) with suitable dairy-free alternatives.")
        }
        if options.contains(.spicier) {
            instructions.append("Make this recipe spicier — increase existing chilies/spices or add appropriate heat, while keeping the dish's overall flavor profile.")
        }
        if options.contains(.kidFriendly) {
            instructions.append("Make this recipe more kid-friendly — mild flavors, less spice, familiar and approachable ingredients.")
        }

        guard !instructions.isEmpty else { return pastedText }

        let instructionsBlock = instructions.map { "- \($0)" }.joined(separator: "\n")
        return """
        \(pastedText)

        Additional optimization instructions for this recipe:
        \(instructionsBlock)
        """
    }
}
