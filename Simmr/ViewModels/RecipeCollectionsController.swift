//
//  RecipeCollectionsController.swift
//  Simmr
//
//  Owns the dashboard recipe-library lifecycle and filter state. Views do
//  not fetch Firestore or reshape collection documents directly.
//

import Combine
import Foundation

@MainActor
final class RecipeCollectionsController: ObservableObject {
    @Published private(set) var collections: [RecipeCollection] = []
    @Published private(set) var filterOptions = RecipeFilterOptions.empty
    @Published private(set) var isLoading = false
    @Published private(set) var hasLoaded = false
    @Published private(set) var errorMessage: String?
    @Published var selectedFilters = RecipeFilterSelection()

    private let provider: RecipeCollectionsProviding

    init(provider: RecipeCollectionsProviding? = nil) {
        self.provider = provider ?? BackendRecipeCollectionsService()
    }

    var visibleCollections: [RecipeCollection] {
        guard !selectedFilters.isEmpty else { return collections }

        return collections.compactMap { collection in
            let recipes = collection.recipes.filter {
                selectedFilters.matches($0.recipe)
            }
            guard !recipes.isEmpty else { return nil }
            return RecipeCollection(
                id: collection.id,
                name: collection.name,
                description: collection.description,
                slug: collection.slug,
                displayOrder: collection.displayOrder,
                isFeatured: collection.isFeatured,
                recipes: recipes
            )
        }
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await refresh()
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer {
            isLoading = false
            hasLoaded = true
        }

        do {
            let response = try await provider.fetchRecipeCollections()
            collections = response.collections
            filterOptions = response.filters
            removeUnavailableSelections()
        } catch let error as LocalizedError {
            errorMessage = error.errorDescription ?? "Couldn't load recipes."
        } catch {
            errorMessage = "Couldn't load recipes."
        }
    }

    func clearFilters() {
        selectedFilters.clear()
    }

    private func removeUnavailableSelections() {
        selectedFilters.cuisines.formIntersection(filterOptions.cuisines)
        selectedFilters.mealTypes.formIntersection(filterOptions.mealTypes)
        selectedFilters.dietaryTags.formIntersection(filterOptions.dietaryTags)
        selectedFilters.difficulties.formIntersection(filterOptions.difficulties)
        selectedFilters.totalTimes.formIntersection(filterOptions.totalTimes)
        selectedFilters.calorieRanges.formIntersection(filterOptions.calorieRanges)
        selectedFilters.servingSizes.formIntersection(filterOptions.servingSizes)
    }
}
