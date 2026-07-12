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

    func generateRecipe(from pastedText: String) async throws -> Recipe {
        guard let apiKey = apiKeyStore.apiKey, !apiKey.isEmpty else {
            throw OpenAIClientError.missingAPIKey
        }

        let client = OpenAIClient(apiKey: apiKey, model: model)
        let data = try await client.createStructuredCompletion(
            systemPrompt: RecipeJSONSchema.systemPrompt,
            userPrompt: pastedText,
            schemaName: RecipeJSONSchema.schemaName,
            schema: RecipeJSONSchema.schema
        )

        do {
            return try JSONDecoder().decode(Recipe.self, from: data)
        } catch {
            throw OpenAIClientError.malformedCompletion
        }
    }
}
