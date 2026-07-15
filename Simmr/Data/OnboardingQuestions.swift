//
//  OnboardingQuestions.swift
//  Simmr
//
//  The full Kitchen Profile question set. Order matters — this is the
//  flow order, filtered live by each question's isVisible predicate.
//

import Foundation

enum OnboardingQuestions {
    static let all: [OnboardingQuestion] = [
        // MARK: About You

        OnboardingQuestion(
            id: "cook_frequency",
            sectionTitle: "About You",
            text: "How often do you cook?",
            kind: .singleSelect,
            options: [
                OnboardingOption(id: "daily", label: "Every day"),
                OnboardingOption(id: "4_6_week", label: "4–6 times a week"),
                OnboardingOption(id: "2_3_week", label: "2–3 times a week"),
                OnboardingOption(id: "weekends", label: "Weekends"),
                OnboardingOption(id: "once_week", label: "Once a week"),
                OnboardingOption(id: "rarely", label: "Rarely"),
                OnboardingOption(id: "just_starting", label: "I'm just starting to cook"),
            ]
        ),

        OnboardingQuestion(
            id: "cook_for",
            sectionTitle: "About You",
            text: "Who do you usually cook for?",
            kind: .multiSelect(maxSelections: nil),
            options: [
                OnboardingOption(id: "me", label: "Me"),
                OnboardingOption(id: "partner", label: "Partner"),
                OnboardingOption(id: "kids", label: "Kids"),
                OnboardingOption(id: "parents", label: "Parents"),
                OnboardingOption(id: "friends", label: "Friends"),
            ]
        ),

        // MARK: Your Cooking Style

        OnboardingQuestion(
            id: "confidence",
            sectionTitle: "Your Cooking Style",
            text: "How confident are you in the kitchen?",
            kind: .singleSelect,
            options: [
                OnboardingOption(id: "never_cooked", label: "Never cooked before"),
                OnboardingOption(id: "beginner", label: "Beginner"),
                OnboardingOption(id: "comfortable", label: "Comfortable"),
                OnboardingOption(id: "experienced", label: "Experienced"),
                OnboardingOption(id: "experimenter", label: "I love experimenting"),
            ]
        ),

        OnboardingQuestion(
            id: "why_cook",
            sectionTitle: "Your Cooking Style",
            text: "Why do you cook?",
            kind: .multiSelect(maxSelections: nil),
            options: [
                OnboardingOption(id: "eat_healthier", label: "Eat healthier"),
                OnboardingOption(id: "enjoy_cooking", label: "Enjoy cooking"),
                OnboardingOption(id: "family_responsibility", label: "Family responsibility"),
                OnboardingOption(id: "meal_prep", label: "Meal prep"),
                OnboardingOption(id: "fitness", label: "Fitness"),
                OnboardingOption(id: "relaxation", label: "Relaxation"),
            ]
        ),

        OnboardingQuestion(
            id: "frustration",
            sectionTitle: "Your Cooking Style",
            text: "What's your biggest cooking frustration?",
            kind: .multiSelect(maxSelections: 3),
            options: [
                OnboardingOption(id: "dont_know_what", label: "I never know what to cook"),
                OnboardingOption(id: "confusing_recipes", label: "Recipes are confusing"),
                OnboardingOption(id: "takes_too_long", label: "Cooking takes too long"),
                OnboardingOption(id: "wasting_ingredients", label: "Wasting ingredients"),
                OnboardingOption(id: "healthy_boring", label: "Healthy food is boring"),
                OnboardingOption(id: "forget_recipes", label: "I forget recipes"),
            ]
        ),

        // MARK: Your Kitchen

        OnboardingQuestion(
            id: "appliances",
            sectionTitle: "Your Kitchen",
            text: "Which appliances do you have?",
            kind: .multiSelect(maxSelections: nil),
            options: [
                OnboardingOption(id: "gas_stove", label: "Gas stove"),
                OnboardingOption(id: "induction", label: "Induction"),
                OnboardingOption(id: "microwave", label: "Microwave"),
                OnboardingOption(id: "oven", label: "Oven"),
                OnboardingOption(id: "otg", label: "OTG"),
                OnboardingOption(id: "air_fryer", label: "Air fryer"),
                OnboardingOption(id: "pressure_cooker", label: "Pressure cooker"),
                OnboardingOption(id: "instant_pot", label: "Instant Pot"),
                OnboardingOption(id: "mixer_blender", label: "Mixer / Blender"),
                OnboardingOption(id: "food_processor", label: "Food processor"),
            ]
        ),

        OnboardingQuestion(
            id: "time_available",
            sectionTitle: "Your Kitchen",
            text: "How much time do you usually have to cook?",
            kind: .singleSelect,
            options: [
                OnboardingOption(id: "under_15", label: "Under 15 mins"),
                OnboardingOption(id: "15_30", label: "15–30 mins"),
                OnboardingOption(id: "30_45", label: "30–45 mins"),
                OnboardingOption(id: "45_60", label: "45–60 mins"),
                OnboardingOption(id: "over_60", label: "More than an hour"),
            ]
        ),

        OnboardingQuestion(
            id: "meals_cooked",
            sectionTitle: "Your Kitchen",
            text: "Which meals do you usually cook?",
            kind: .multiSelect(maxSelections: nil),
            options: [
                OnboardingOption(id: "breakfast", label: "Breakfast"),
                OnboardingOption(id: "lunch", label: "Lunch"),
                OnboardingOption(id: "dinner", label: "Dinner"),
                OnboardingOption(id: "snacks", label: "Snacks"),
                OnboardingOption(id: "desserts", label: "Desserts"),
                OnboardingOption(id: "drinks", label: "Drinks"),
                OnboardingOption(id: "meal_prep_meals", label: "Meal prep"),
            ]
        ),

        // MARK: Food Preferences

        OnboardingQuestion(
            id: "diet",
            sectionTitle: "Food Preferences",
            text: "Which best describes your diet?",
            kind: .multiSelect(maxSelections: nil),
            options: [
                OnboardingOption(id: "vegetarian", label: "Vegetarian"),
                OnboardingOption(id: "eggetarian", label: "Eggetarian"),
                OnboardingOption(id: "vegan", label: "Vegan"),
                OnboardingOption(id: "chicken", label: "Chicken"),
                OnboardingOption(id: "fish", label: "Fish"),
                OnboardingOption(id: "seafood", label: "Seafood"),
                OnboardingOption(id: "beef", label: "Beef"),
                OnboardingOption(id: "pork", label: "Pork"),
                OnboardingOption(id: "no_preference", label: "No preference", isExclusive: true),
            ]
        ),

        // MARK: Dietary Restrictions & Health

        OnboardingQuestion(
            id: "restrictions",
            sectionTitle: "Dietary Restrictions & Health",
            text: "Do any of these apply to you?",
            kind: .multiSelect(maxSelections: nil),
            options: [
                OnboardingOption(id: "has_allergies", label: "🚫 I have food allergies"),
                OnboardingOption(id: "has_medical", label: "🩺 I have a medical condition that affects what I eat"),
                OnboardingOption(id: "avoids_by_choice", label: "🌱 I avoid certain foods by choice"),
                OnboardingOption(id: "none_restrictions", label: "✅ None of these", isExclusive: true),
            ]
        ),

        OnboardingQuestion(
            id: "allergies",
            sectionTitle: "Dietary Restrictions & Health",
            text: "Food Allergies",
            kind: .multiSelect(maxSelections: nil),
            groups: [
                OnboardingOptionGroup(id: "nuts", title: "Nuts", options: [
                    OnboardingOption(id: "peanuts", label: "Peanuts"),
                    OnboardingOption(id: "almonds", label: "Almonds"),
                    OnboardingOption(id: "cashews", label: "Cashews"),
                    OnboardingOption(id: "walnuts", label: "Walnuts"),
                    OnboardingOption(id: "pistachios", label: "Pistachios"),
                    OnboardingOption(id: "other_tree_nuts", label: "Other tree nuts"),
                ]),
                OnboardingOptionGroup(id: "dairy_eggs", title: "Dairy & Eggs", options: [
                    OnboardingOption(id: "milk", label: "Milk"),
                    OnboardingOption(id: "cheese", label: "Cheese"),
                    OnboardingOption(id: "butter", label: "Butter"),
                    OnboardingOption(id: "eggs", label: "Eggs"),
                ]),
                OnboardingOptionGroup(id: "grains", title: "Grains", options: [
                    OnboardingOption(id: "wheat", label: "Wheat"),
                    OnboardingOption(id: "gluten", label: "Gluten"),
                ]),
                OnboardingOptionGroup(id: "soy_legumes", title: "Soy & Legumes", options: [
                    OnboardingOption(id: "soy", label: "Soy"),
                ]),
                OnboardingOptionGroup(id: "seafood_allergy", title: "Seafood", options: [
                    OnboardingOption(id: "allergy_fish", label: "Fish"),
                    OnboardingOption(id: "shellfish", label: "Shellfish"),
                ]),
                OnboardingOptionGroup(id: "seeds_others", title: "Seeds & Others", options: [
                    OnboardingOption(id: "sesame", label: "Sesame"),
                    OnboardingOption(id: "mustard", label: "Mustard"),
                    OnboardingOption(id: "corn", label: "Corn"),
                ]),
            ],
            allowsOtherText: true,
            isVisible: { $0["restrictions"]?.selectedOptionIDs.contains("has_allergies") ?? false }
        ),

        OnboardingQuestion(
            id: "medical_conditions",
            sectionTitle: "Dietary Restrictions & Health",
            text: "Medical Conditions",
            subtitle: "We'll use this only to recommend recipes that better suit your dietary needs. This isn't medical advice.",
            kind: .multiSelect(maxSelections: nil),
            groups: [
                OnboardingOptionGroup(id: "blood_sugar", title: "Blood Sugar", options: [
                    OnboardingOption(id: "diabetes", label: "Diabetes"),
                    OnboardingOption(id: "prediabetes", label: "Prediabetes"),
                ]),
                OnboardingOptionGroup(id: "heart_health", title: "Heart Health", options: [
                    OnboardingOption(id: "high_blood_pressure", label: "High blood pressure"),
                    OnboardingOption(id: "high_cholesterol", label: "High cholesterol"),
                    OnboardingOption(id: "heart_disease", label: "Heart disease"),
                ]),
                OnboardingOptionGroup(id: "digestive_health", title: "Digestive Health", options: [
                    OnboardingOption(id: "ibs", label: "IBS"),
                    OnboardingOption(id: "acid_reflux", label: "Acid reflux (GERD)"),
                    OnboardingOption(id: "lactose_intolerance", label: "Lactose intolerance"),
                    OnboardingOption(id: "celiac_disease", label: "Celiac disease"),
                    OnboardingOption(id: "gluten_sensitivity", label: "Gluten sensitivity"),
                ]),
                OnboardingOptionGroup(id: "hormonal_metabolic", title: "Hormonal & Metabolic", options: [
                    OnboardingOption(id: "pcos_pcod", label: "PCOS / PCOD"),
                    OnboardingOption(id: "thyroid_condition", label: "Thyroid condition"),
                ]),
                OnboardingOptionGroup(id: "kidney_liver", title: "Kidney & Liver", options: [
                    OnboardingOption(id: "kidney_disease", label: "Kidney disease"),
                    OnboardingOption(id: "fatty_liver", label: "Fatty liver"),
                ]),
                OnboardingOptionGroup(id: "life_stage", title: "Life Stage", options: [
                    OnboardingOption(id: "pregnancy", label: "Pregnancy"),
                    OnboardingOption(id: "breastfeeding", label: "Breastfeeding"),
                ]),
            ],
            allowsOtherText: true,
            isVisible: { $0["restrictions"]?.selectedOptionIDs.contains("has_medical") ?? false }
        ),

        OnboardingQuestion(
            id: "foods_avoided",
            sectionTitle: "Dietary Restrictions & Health",
            text: "Foods You Avoid",
            kind: .multiSelect(maxSelections: nil),
            options: [
                OnboardingOption(id: "avoid_beef", label: "Beef"),
                OnboardingOption(id: "avoid_pork", label: "Pork"),
                OnboardingOption(id: "avoid_seafood", label: "Seafood"),
                OnboardingOption(id: "avoid_eggs", label: "Eggs"),
                OnboardingOption(id: "avoid_dairy", label: "Dairy"),
                OnboardingOption(id: "avoid_onion", label: "Onion"),
                OnboardingOption(id: "avoid_garlic", label: "Garlic"),
                OnboardingOption(id: "avoid_mushrooms", label: "Mushrooms"),
                OnboardingOption(id: "avoid_alcohol", label: "Alcohol"),
                OnboardingOption(id: "avoid_caffeine", label: "Caffeine"),
                OnboardingOption(id: "avoid_added_sugar", label: "Added sugar"),
            ],
            allowsOtherText: true,
            isVisible: { $0["restrictions"]?.selectedOptionIDs.contains("avoids_by_choice") ?? false }
        ),

        // MARK: Health Goals

        OnboardingQuestion(
            id: "nutrition_goals",
            sectionTitle: "Health Goals",
            text: "What are your current nutrition goals?",
            kind: .multiSelect(maxSelections: nil),
            options: [
                OnboardingOption(id: "lose_weight", label: "Lose weight"),
                OnboardingOption(id: "build_muscle", label: "Build muscle"),
                OnboardingOption(id: "maintain_weight", label: "Maintain weight"),
                OnboardingOption(id: "more_protein", label: "Eat more protein"),
                OnboardingOption(id: "more_vegetables", label: "Eat more vegetables"),
                OnboardingOption(id: "improve_digestion", label: "Improve digestion"),
                OnboardingOption(id: "reduce_sugar", label: "Reduce sugar"),
                OnboardingOption(id: "increase_fibre", label: "Increase fibre"),
            ],
            allowsOtherText: true
        ),

        // MARK: Taste Preferences

        OnboardingQuestion(
            id: "cuisines",
            sectionTitle: "Taste Preferences",
            text: "Which cuisines do you enjoy the most?",
            kind: .multiSelect(maxSelections: 5),
            options: [
                OnboardingOption(id: "indian", label: "Indian"),
                OnboardingOption(id: "italian", label: "Italian"),
                OnboardingOption(id: "chinese", label: "Chinese"),
                OnboardingOption(id: "thai", label: "Thai"),
                OnboardingOption(id: "japanese", label: "Japanese"),
                OnboardingOption(id: "korean", label: "Korean"),
                OnboardingOption(id: "mexican", label: "Mexican"),
                OnboardingOption(id: "mediterranean", label: "Mediterranean"),
                OnboardingOption(id: "middle_eastern", label: "Middle Eastern"),
                OnboardingOption(id: "american", label: "American"),
            ],
            allowsOtherText: true
        ),

        OnboardingQuestion(
            id: "spice_level",
            sectionTitle: "Taste Preferences",
            text: "How spicy do you like your food?",
            kind: .singleSelect,
            options: [
                OnboardingOption(id: "mild", label: "Mild"),
                OnboardingOption(id: "medium", label: "Medium"),
                OnboardingOption(id: "spicy", label: "Spicy"),
                OnboardingOption(id: "very_spicy", label: "Very spicy"),
            ]
        ),

        // MARK: AI Personalization

        OnboardingQuestion(
            id: "ai_help",
            sectionTitle: "AI Personalization",
            text: "What would you like your AI cooking companion to help you with?",
            subtitle: "Rank your top 3",
            kind: .ranking(count: 3),
            options: [
                OnboardingOption(id: "decide_what_to_cook", label: "Decide what to cook"),
                OnboardingOption(id: "step_by_step_cooking", label: "Step-by-step cooking"),
                OnboardingOption(id: "ingredient_substitutions", label: "Ingredient substitutions"),
                OnboardingOption(id: "explain_techniques", label: "Explain cooking techniques"),
                OnboardingOption(id: "grocery_lists", label: "Grocery lists"),
                OnboardingOption(id: "meal_planning", label: "Meal planning"),
                OnboardingOption(id: "healthier_alternatives", label: "Healthier alternatives"),
                OnboardingOption(id: "nutrition_insights", label: "Nutrition insights"),
                OnboardingOption(id: "portion_sizing", label: "Portion sizing"),
                OnboardingOption(id: "leftover_ideas", label: "Leftover ideas"),
            ]
        ),

        OnboardingQuestion(
            id: "measurement_units",
            sectionTitle: "AI Personalization",
            text: "How would you like measurements to be shown?",
            kind: .singleSelect,
            options: [
                OnboardingOption(id: "metric", label: "Metric"),
                OnboardingOption(id: "us_cups", label: "US Cups"),
                OnboardingOption(id: "both_units", label: "Both"),
            ]
        ),
    ]
}
