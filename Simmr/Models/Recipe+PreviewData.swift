//
//  Recipe+PreviewData.swift
//  Simmr
//
//  Sample data for SwiftUI previews only.
//

import Foundation

extension Recipe {
    static var preview: Recipe {
        Recipe(
            title: "Creamy Garlic Parmesan Pasta",
            servings: 4,
            ingredients: [
                Ingredient(name: "Spaghetti", quantity: 12, unit: "oz"),
                Ingredient(name: "Butter", quantity: 3, unit: "tbsp"),
                Ingredient(name: "Garlic cloves, minced", quantity: 4, unit: "cloves"),
                Ingredient(name: "Heavy cream", quantity: 1, unit: "cup"),
                Ingredient(name: "Parmesan cheese, grated", quantity: 1, unit: "cup"),
            ],
            steps: [
                Step(title: "Boil the pasta", instruction: "Bring a large pot of salted water to a boil and cook the spaghetti until al dente.", timerSeconds: 600),
                Step(title: "Sauté the garlic", instruction: "Melt the butter in a large skillet over medium heat and sauté the minced garlic until fragrant.", timerSeconds: 120),
                Step(title: "Add the parmesan", instruction: "Whisk in the parmesan cheese until the sauce turns smooth and glossy.", timerSeconds: nil),
            ]
        )
    }
}
