//
//  FeedbackImproveCategory.swift
//  Simmr
//
//  The negative/neutral flow's two-step drill-down: pick a broad category,
//  then one specific reason within it — no typing anywhere, structured
//  enough to actually be actionable, and fast enough to finish in two taps
//  after the star rating.
//

import Foundation

enum FeedbackImproveCategory: String, CaseIterable, Identifiable, Codable {
    case recipe
    case cookingGuidance
    case aiGeneration
    case appExperience

    var id: String { rawValue }

    var label: String {
        switch self {
        case .recipe: "🍳 The recipe"
        case .cookingGuidance: "👨‍🍳 The cooking guidance"
        case .aiGeneration: "🤖 AI recipe generation"
        case .appExperience: "📱 The app experience"
        }
    }

    var detailTitle: String {
        switch self {
        case .recipe: "What was wrong with the recipe?"
        case .cookingGuidance: "What was confusing?"
        case .aiGeneration: "What went wrong?"
        case .appExperience: "What should we improve?"
        }
    }

    var detailOptions: [String] {
        switch self {
        case .recipe:
            [
                "Didn't taste as expected",
                "Ingredient quantities felt off",
                "Needed better cooking tips",
                "Recipe was too complicated",
            ]
        case .cookingGuidance:
            [
                "Instructions weren't clear",
                "Steps were hard to follow",
                "Timers weren't helpful",
                "Too much reading while cooking",
            ]
        case .aiGeneration:
            [
                "Didn't understand my recipe",
                "Missing ingredients or steps",
                "Didn't match what I wanted",
                "Optimization wasn't useful",
            ]
        case .appExperience:
            [
                "Navigation was confusing",
                "Too many taps",
                "Performance issue",
                "Live Activity / Timer experience",
            ]
        }
    }
}
