//
//  IngredientSection.swift
//  Simmr
//
//  Groups a flat ingredient list into sections (Marinade, Curry, Garnish...)
//  while preserving first-seen order. Un-sectioned ingredients share a group
//  with a nil title so views can skip rendering a header for them.
//

import Foundation

struct IngredientSection: Identifiable {
    let id: String
    let title: String?
    let ingredients: [Ingredient]
}

extension Array where Element == Ingredient {
    var groupedBySection: [IngredientSection] {
        var order: [String] = []
        var buckets: [String: [Ingredient]] = [:]

        for ingredient in self {
            let key = ingredient.section ?? ""
            if buckets[key] == nil {
                order.append(key)
                buckets[key] = []
            }
            buckets[key]?.append(ingredient)
        }

        return order.map { key in
            IngredientSection(
                id: key.isEmpty ? "_ungrouped" : key,
                title: key.isEmpty ? nil : key,
                ingredients: buckets[key] ?? []
            )
        }
    }
}
