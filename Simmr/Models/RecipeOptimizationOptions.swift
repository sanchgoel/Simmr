//
//  RecipeOptimizationOptions.swift
//  Simmr
//
//  User-selectable toggles on the Home screen that steer how OpenAI adapts
//  a pasted recipe (see RecipeParserService for how these become prompt
//  instructions).
//

import Foundation

struct RecipeOptimizationOptions: OptionSet, Hashable {
    let rawValue: Int

    static let lowerCalories = RecipeOptimizationOptions(rawValue: 1 << 0)
    static let higherProtein = RecipeOptimizationOptions(rawValue: 1 << 1)
    static let lowerSugar = RecipeOptimizationOptions(rawValue: 1 << 2)
    static let lowCarb = RecipeOptimizationOptions(rawValue: 1 << 3)
    static let dairyFree = RecipeOptimizationOptions(rawValue: 1 << 4)
    static let spicier = RecipeOptimizationOptions(rawValue: 1 << 5)
    static let kidFriendly = RecipeOptimizationOptions(rawValue: 1 << 6)
}
