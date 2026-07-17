//
//  Recipe.swift
//  Simmr
//
//  Core recipe data model. Matches the JSON Schema sent to OpenAI's
//  Structured Outputs (see RecipeJSONSchema) field-for-field, so decoding a
//  model response is a direct JSONDecoder pass with no translation layer.
//

import Foundation

struct Recipe: Codable, Identifiable, Hashable {
    let id: UUID = UUID()
    var title: String
    var description: String?
    var servings: Int
    var prepTimeMinutes: Int?
    var cookTimeMinutes: Int?
    /// Estimated calories per serving, not per the whole recipe — doesn't
    /// need rescaling when the user adjusts the servings stepper.
    var caloriesPerServing: Int?
    /// A short note on what was adjusted to satisfy the user's selected
    /// optimization toggles (e.g. "Used less oil and swapped in Greek
    /// yogurt to cut calories"). Nil when no optimizations were requested.
    var optimizationSummary: String?
    var difficulty: String? = nil
    var cuisine: String? = nil
    var mealType: [String] = []
    var dietaryTags: [String] = []
    var ingredients: [Ingredient]
    var steps: [RecipeStep]

    private enum CodingKeys: String, CodingKey {
        case title, description, servings, prepTimeMinutes, cookTimeMinutes, caloriesPerServing, optimizationSummary, difficulty, cuisine, mealType, dietaryTags, ingredients, steps
    }
}

struct Ingredient: Codable, Identifiable, Hashable {
    let id: UUID = UUID()
    var name: String
    var quantity: Double? = nil
    var unit: String? = nil
    /// Ingredient group such as "Marinade", "Curry", "Garnish". Nil if the recipe isn't sectioned.
    var section: String? = nil
    var optional: Bool = false
    /// Short prep note such as "finely minced" or "diced". Nil if the ingredient needs no prep.
    var prep: String? = nil
    var checked: Bool = false

    private enum CodingKeys: String, CodingKey {
        case name, quantity, unit, section, optional, prep
    }

    /// Quantity and unit combined for display (e.g. "1½ cup"), or nil if neither is known.
    var quantityLabel: String? {
        switch (quantity, unit) {
        case let (quantity?, unit?): return "\(QuantityFormatter.format(quantity)) \(unit)"
        case let (quantity?, nil): return QuantityFormatter.format(quantity)
        case let (nil, unit?): return unit
        case (nil, nil): return nil
        }
    }
}

struct RecipeStep: Codable, Identifiable, Hashable {
    let id: UUID = UUID()
    var stepNumber: Int
    var title: String
    var instruction: String
    /// Names of ingredients used in this step, as they appear in `Recipe.ingredients`.
    var ingredientsUsed: [String] = []
    var timerSeconds: Int? = nil
    var tips: String? = nil
    var cookware: String? = nil
    var heatLevel: String? = nil
    /// "on" or "off", when a lid is relevant to this step. Nil otherwise.
    var lid: String? = nil
    var visualCue: String? = nil

    private enum CodingKeys: String, CodingKey {
        case stepNumber, title, instruction, ingredientsUsed, timerSeconds, tips, cookware, heatLevel, lid, visualCue
    }

    var hasTimer: Bool { timerSeconds != nil }
}
