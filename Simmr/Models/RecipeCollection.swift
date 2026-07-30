//
//  RecipeCollection.swift
//  Simmr
//
//  Mobile contract for the backend's curated recipe-library response.
//  Firestore's draft/published wrappers stay server-side; the dashboard only
//  receives published collections and published recipes.
//

import Foundation

struct RecipeCollection: Decodable, Identifiable {
    let id: String
    let name: String
    let description: String
    let slug: String
    let displayOrder: Int
    let isFeatured: Bool
    let recipes: [LibraryRecipe]
}

struct LibraryRecipe: Decodable, Identifiable {
    let id: String
    let filterIds: [String]
    let recipe: Recipe
}

struct RecipeFilterOptions: Decodable {
    let cuisines: [String]
    let mealTypes: [String]
    let dietaryTags: [String]
    let difficulties: [String]
    let totalTimes: [String]
    let calorieRanges: [String]
    let servingSizes: [String]

    static let empty = RecipeFilterOptions(
        cuisines: [],
        mealTypes: [],
        dietaryTags: [],
        difficulties: [],
        totalTimes: [],
        calorieRanges: [],
        servingSizes: []
    )

    var isEmpty: Bool {
        cuisines.isEmpty &&
        mealTypes.isEmpty &&
        dietaryTags.isEmpty &&
        difficulties.isEmpty &&
        totalTimes.isEmpty &&
        calorieRanges.isEmpty &&
        servingSizes.isEmpty
    }

    private enum CodingKeys: String, CodingKey {
        case cuisines
        case mealTypes
        case dietaryTags
        case difficulties
        case totalTimes
        case calorieRanges
        case servingSizes
    }

    init(
        cuisines: [String],
        mealTypes: [String],
        dietaryTags: [String],
        difficulties: [String],
        totalTimes: [String],
        calorieRanges: [String],
        servingSizes: [String]
    ) {
        self.cuisines = cuisines
        self.mealTypes = mealTypes
        self.dietaryTags = dietaryTags
        self.difficulties = difficulties
        self.totalTimes = totalTimes
        self.calorieRanges = calorieRanges
        self.servingSizes = servingSizes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cuisines = try container.decodeIfPresent([String].self, forKey: .cuisines) ?? []
        mealTypes = try container.decodeIfPresent([String].self, forKey: .mealTypes) ?? []
        dietaryTags = try container.decodeIfPresent([String].self, forKey: .dietaryTags) ?? []
        difficulties = try container.decodeIfPresent([String].self, forKey: .difficulties) ?? []
        totalTimes = try container.decodeIfPresent([String].self, forKey: .totalTimes) ?? []
        calorieRanges = try container.decodeIfPresent([String].self, forKey: .calorieRanges) ?? []
        servingSizes = try container.decodeIfPresent([String].self, forKey: .servingSizes) ?? []
    }
}

struct RecipeFilterSelection: Equatable {
    var cuisines: Set<String> = []
    var mealTypes: Set<String> = []
    var dietaryTags: Set<String> = []
    var difficulties: Set<String> = []
    var totalTimes: Set<String> = []
    var calorieRanges: Set<String> = []
    var servingSizes: Set<String> = []

    var count: Int {
        cuisines.count +
        mealTypes.count +
        dietaryTags.count +
        difficulties.count +
        totalTimes.count +
        calorieRanges.count +
        servingSizes.count
    }

    var isEmpty: Bool { count == 0 }

    mutating func clear() {
        self = RecipeFilterSelection()
    }

    func matches(_ recipe: Recipe) -> Bool {
        matchesSingleValue(recipe.cuisine, selected: cuisines) &&
        matchesAnyValue(recipe.mealType, selected: mealTypes) &&
        matchesAnyValue(recipe.dietaryTags, selected: dietaryTags) &&
        matchesSingleValue(recipe.difficulty, selected: difficulties) &&
        matchesTotalTime(recipe) &&
        matchesCalories(recipe) &&
        matchesServingSize(recipe)
    }

    private func matchesSingleValue(_ value: String?, selected: Set<String>) -> Bool {
        guard !selected.isEmpty else { return true }
        guard let value else { return false }
        return selected.contains(where: { $0.caseInsensitiveCompare(value) == .orderedSame })
    }

    private func matchesAnyValue(_ values: [String], selected: Set<String>) -> Bool {
        guard !selected.isEmpty else { return true }
        return values.contains { value in
            selected.contains(where: { $0.caseInsensitiveCompare(value) == .orderedSame })
        }
    }

    private func matchesTotalTime(_ recipe: Recipe) -> Bool {
        guard !totalTimes.isEmpty else { return true }
        let times = [recipe.prepTimeMinutes, recipe.cookTimeMinutes].compactMap { $0 }
        guard !times.isEmpty else { return false }
        let total = times.reduce(0, +)

        return totalTimes.contains { range in
            switch range {
            case "Under 30 min": total < 30
            case "30–60 min": total >= 30 && total <= 60
            case "Over 60 min": total > 60
            default: false
            }
        }
    }

    private func matchesCalories(_ recipe: Recipe) -> Bool {
        guard !calorieRanges.isEmpty else { return true }
        guard let calories = recipe.caloriesPerServing else { return false }

        return calorieRanges.contains { range in
            switch range {
            case "Under 400 kcal": calories < 400
            case "400–600 kcal": calories >= 400 && calories <= 600
            case "Over 600 kcal": calories > 600
            default: false
            }
        }
    }

    private func matchesServingSize(_ recipe: Recipe) -> Bool {
        guard !servingSizes.isEmpty else { return true }

        return servingSizes.contains { range in
            switch range {
            case "1–2 servings": recipe.servings <= 2
            case "3–4 servings": recipe.servings >= 3 && recipe.servings <= 4
            case "5+ servings": recipe.servings >= 5
            default: false
            }
        }
    }
}

struct RecipeCollectionsResponse: Decodable {
    let collections: [RecipeCollection]
    let filters: RecipeFilterOptions
}
