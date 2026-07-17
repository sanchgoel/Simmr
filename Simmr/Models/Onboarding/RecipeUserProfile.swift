//
//  RecipeUserProfile.swift
//  Simmr
//
//  The subset of the user's Kitchen Profile answers sent to OpenAI to
//  personalize recipe generation (see RecipeParserService). Field names
//  match the API contract the recipe prompt expects; values are the app's
//  own internal onboarding option ids (see OnboardingQuestions) passed
//  straight through — they're already short, self-descriptive snake_case
//  strings the model can interpret directly, so this avoids maintaining a
//  second, parallel vocabulary that could drift from the question
//  definitions.
//

import Foundation

struct RecipeUserProfile: Encodable {
    var cookingFrequency: String?
    var cooksFor: [String]
    var cookingSkill: String?
    var cookingMotivations: [String]
    var cookingFrustrations: [String]
    var availableAppliances: [String]
    var availableCookingTime: String?
    var mealsCooked: [String]
    var diet: [String]
    var foodAllergies: [String]
    var medicalConditions: [String]
    var foodsToAvoid: [String]
    var nutritionGoals: [String]
    var preferredCuisines: [String]
    var spicePreference: String?
    var assistantPreferences: [String]
    var measurementSystem: String?

    /// Builds the profile sent to the API from raw onboarding answers.
    /// Each question's `otherText` (when present) is appended to that
    /// question's array alongside its selected option ids.
    static func build(from answers: OnboardingAnswers) -> RecipeUserProfile {
        func values(for questionID: String) -> [String] {
            let answer = answers[questionID]
            var result = answer?.selectedOptionIDs ?? []
            let other = answer?.otherText.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !other.isEmpty { result.append(other) }
            return result
        }
        func singleValue(for questionID: String) -> String? {
            values(for: questionID).first
        }

        return RecipeUserProfile(
            cookingFrequency: singleValue(for: "cook_frequency"),
            cooksFor: values(for: "cook_for"),
            cookingSkill: singleValue(for: "confidence"),
            cookingMotivations: values(for: "why_cook"),
            cookingFrustrations: values(for: "frustration"),
            availableAppliances: values(for: "appliances"),
            availableCookingTime: singleValue(for: "time_available"),
            mealsCooked: values(for: "meals_cooked"),
            diet: values(for: "diet"),
            foodAllergies: values(for: "allergies"),
            medicalConditions: values(for: "medical_conditions"),
            foodsToAvoid: values(for: "foods_avoided"),
            nutritionGoals: values(for: "nutrition_goals"),
            preferredCuisines: values(for: "cuisines"),
            spicePreference: singleValue(for: "spice_level"),
            assistantPreferences: values(for: "ai_help"),
            measurementSystem: singleValue(for: "measurement_units")
        )
    }
}
