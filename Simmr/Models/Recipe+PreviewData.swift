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
            title: "Chicken Tikka Masala",
            description: "Charred, marinated chicken simmered in a rich, spiced tomato-cream curry.",
            servings: 4,
            prepTimeMinutes: 20,
            cookTimeMinutes: 35,
            caloriesPerServing: 480,
            ingredients: [
                Ingredient(name: "Chicken thighs, cubed", quantity: 1.5, unit: "lb", section: "Marinade", optional: false),
                Ingredient(name: "Plain yogurt", quantity: 0.5, unit: "cup", section: "Marinade", optional: false),
                Ingredient(name: "Garam masala", quantity: 2, unit: "tsp", section: "Marinade", optional: false),
                Ingredient(name: "Butter", quantity: 3, unit: "tbsp", section: "Curry", optional: false),
                Ingredient(name: "Onion, diced", quantity: 1, unit: nil, section: "Curry", optional: false),
                Ingredient(name: "Crushed tomatoes", quantity: 1, unit: "can", section: "Curry", optional: false),
                Ingredient(name: "Salt", quantity: nil, unit: nil, section: "Curry", optional: false),
                Ingredient(name: "Fresh cilantro, chopped", quantity: 2, unit: "tbsp", section: "Garnish", optional: true),
            ],
            steps: [
                RecipeStep(
                    stepNumber: 1,
                    title: "Marinate the chicken",
                    instruction: "Combine chicken with yogurt and garam masala. Cover and refrigerate.",
                    ingredientsUsed: ["Chicken thighs, cubed", "Plain yogurt", "Garam masala"],
                    timerSeconds: 1800,
                    tips: "The longer it marinates, the more tender the chicken gets."
                ),
                RecipeStep(
                    stepNumber: 2,
                    title: "Sear the chicken",
                    instruction: "Melt butter in a hot skillet and sear the marinated chicken until charred at the edges.",
                    ingredientsUsed: ["Butter", "Chicken thighs, cubed"],
                    timerSeconds: 420,
                    tips: nil
                ),
                RecipeStep(
                    stepNumber: 3,
                    title: "Simmer the sauce",
                    instruction: "Stir in crushed tomatoes and salt. Return the chicken to the skillet and simmer.",
                    ingredientsUsed: ["Crushed tomatoes", "Salt", "Chicken thighs, cubed"],
                    timerSeconds: 900,
                    tips: "Simmer uncovered so the sauce thickens rather than staying thin."
                ),
            ]
        )
    }
}
