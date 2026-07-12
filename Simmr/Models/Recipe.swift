//
//  Recipe.swift
//  Simmr
//
//  Core recipe data model. Decoded from local JSON today; the shape is what
//  an AI-parsed recipe would need to fill in later (see RecipeGenerating).
//

import Foundation

struct Recipe: Codable, Identifiable, Hashable {
    let id: UUID = UUID()
    var title: String
    var servings: Int
    var ingredients: [Ingredient]
    var steps: [Step]

    private enum CodingKeys: String, CodingKey {
        case title, servings, ingredients, steps
    }
}

struct Ingredient: Codable, Identifiable, Hashable {
    let id: UUID = UUID()
    var name: String
    var quantity: Double
    var unit: String
    var checked: Bool = false

    private enum CodingKeys: String, CodingKey {
        case name, quantity, unit
    }
}

struct Step: Codable, Identifiable, Hashable {
    let id: UUID = UUID()
    var title: String
    var instruction: String
    var timerSeconds: Int?

    private enum CodingKeys: String, CodingKey {
        case title, instruction, timerSeconds
    }

    var hasTimer: Bool { timerSeconds != nil }
}
