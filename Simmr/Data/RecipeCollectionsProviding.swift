//
//  RecipeCollectionsProviding.swift
//  Simmr
//

import Foundation

protocol RecipeCollectionsProviding {
    func fetchRecipeCollections() async throws -> RecipeCollectionsResponse
}

struct BackendRecipeCollectionsService: RecipeCollectionsProviding {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchRecipeCollections() async throws -> RecipeCollectionsResponse {
        let configuration = try BackendConfiguration.current()
        let client = BackendAPIClient(configuration: configuration, session: session)
        return try await client.get(path: "v1/recipe-collections")
    }
}
