//
//  RecipeSession.swift
//  Simmr
//
//  Shared ViewModel for the Overview → Grocery → Cooking flow. Owns the
//  single source of truth for serving size and ingredient checked state so
//  those stay in sync as the user moves between screens.
//

import Combine
import Foundation

@MainActor
final class RecipeSession: ObservableObject {
    let recipe: Recipe

    @Published var servings: Int {
        didSet { rescaleIngredients() }
    }
    @Published private(set) var ingredients: [Ingredient] = []

    init(recipe: Recipe) {
        self.recipe = recipe
        self.servings = recipe.servings
        rescaleIngredients()
    }

    var title: String { recipe.title }
    var description: String? { recipe.description }
    var steps: [RecipeStep] { recipe.steps }
    var baseServings: Int { recipe.servings }
    var prepTimeMinutes: Int? { recipe.prepTimeMinutes }
    var cookTimeMinutes: Int? { recipe.cookTimeMinutes }

    var scaleFactor: Double {
        Double(servings) / Double(max(recipe.servings, 1))
    }

    var ingredientSections: [IngredientSection] { ingredients.groupedBySection }

    var checkedCount: Int { ingredients.filter(\.checked).count }
    var totalCount: Int { ingredients.count }
    var allIngredientsChecked: Bool { checkedCount == totalCount }

    func toggleChecked(_ ingredient: Ingredient) {
        guard let index = ingredients.firstIndex(where: { $0.id == ingredient.id }) else { return }
        ingredients[index].checked.toggle()
    }

    private func rescaleIngredients() {
        let previousChecked = Dictionary(uniqueKeysWithValues: ingredients.map { ($0.id, $0.checked) })
        let factor = scaleFactor

        ingredients = recipe.ingredients.map { ingredient in
            var scaled = ingredient
            if let quantity = ingredient.quantity {
                scaled.quantity = roundToNearestQuarter(quantity * factor)
            }
            scaled.checked = previousChecked[ingredient.id] ?? false
            return scaled
        }
    }

    private func roundToNearestQuarter(_ value: Double) -> Double {
        (value * 4).rounded() / 4
    }
}
