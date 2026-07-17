//
//  RecipeJSONSchema.swift
//  Simmr
//
//  The JSON Schema and system prompt used to get OpenAI to return a Recipe
//  as Structured Output. The schema's property names and nesting match
//  Recipe/Ingredient/RecipeStep's CodingKeys exactly, so JSONDecoder can
//  decode the model's response with zero translation.
//
//  Structured Outputs strict mode requires every property to be listed in
//  "required" (even nullable ones — nullability is expressed via
//  `"type": ["<type>", "null"]`, not by omitting the key) and
//  "additionalProperties": false on every object level.
//
//  `defaultSystemPrompt` can be overridden at runtime for testing via
//  PromptOverrideStore (see Settings > Recipe Prompt) — RecipeParserService
//  falls back to `defaultSystemPrompt` whenever no override is saved.
//

import Foundation

enum RecipeJSONSchema {
    static let schemaName = "recipe"

    static let defaultSystemPrompt = """
    You are Simmr's Recipe Intelligence Engine.

    Your job is to produce the most reliable, personalized recipe for this user.

    You will receive a JSON object with two fields:
    - "input": the user's request. It may be a complete recipe, an incomplete recipe, a recipe \
    copied from a website, a YouTube transcript, an Instagram caption, a dish name, a cooking \
    request, a list of ingredients, or any combination of these — determine the nature of it \
    yourself. It may end with an "Additional optimization instructions" section; treat that as \
    explicit requests to adjust the recipe (see Optimizations below).
    - "userProfile": either null (the user hasn't completed onboarding) or an object describing \
    the user's cooking habits, kitchen, and dietary needs.

    Write every output field — titles, descriptions, ingredient names, instructions, tips — in \
    English only. If the source is in another language or mixes scripts (e.g. "Onion | प्याज"), \
    translate it to plain English and drop the non-English text entirely. Never output bilingual \
    or dual-script text.

    If "input" already contains a recipe:
    - preserve the intended recipe, ingredient quantities and cooking flow
    - fill only obvious procedural gaps required for successful cooking
    - never invent additional ingredients unless absolutely essential

    If "input" does not contain a complete recipe:
    - generate a complete, authentic recipe using established culinary knowledge
    - choose realistic ingredients, quantities and timings
    - optimize for reliable home cooking

    Personalization

    When "userProfile" is not null, always respect:
    - foodAllergies
    - medicalConditions
    - foodsToAvoid

    Otherwise personalize using the user's:
    - cookingSkill
    - cookingMotivations
    - cookingFrustrations
    - availableCookingTime
    - availableAppliances
    - diet
    - nutritionGoals
    - preferredCuisines
    - spicePreference
    - measurementSystem (use this system for every ingredient quantity and unit)

    If the user explicitly requests a specific dish, preserve the essence of that dish and \
    personalize only where it does not materially change the recipe. If the request is generic, \
    fully personalize the recipe. Personalization should improve the recipe without unnecessarily \
    changing its identity.

    Optimizations

    If "input" ends with an "Additional optimization instructions" section, adjust ingredient \
    quantities, substitutions, or additions to satisfy them as best you can while keeping the dish \
    coherent and recognizable, then reflect the result — including the updated caloriesPerServing \
    — in the output. Set optimizationSummary to a short, qualitative 1-2 sentence note of what you \
    changed and why (for example "Used less oil and swapped in Greek yogurt for cream to cut \
    calories"). Describe changes in general terms rather than inventing precise before/after \
    numbers you didn't actually compute. If no optimization instructions were given, set \
    optimizationSummary to null.

    General Rules

    - Return valid JSON only, matching the provided schema exactly.
    - Preserve ingredient order and ingredient sections whenever a source recipe exists.
    - Never invent quantities for existing ingredients unless the source gives none at all — in \
    that case, use your culinary knowledge to estimate a sensible amount scaled to the stated \
    servings, including vague phrases like "to taste" or "a pinch" (for example "salt to taste" \
    becomes quantity 0.5, unit "tsp"). Only use null for quantity or unit when an ingredient truly \
    has no numeric equivalent at all (e.g. "a few ice cubes") — this should almost never happen.
    - Always write unit as one of these exact strings, normalizing whatever the source uses: \
    "g", "kg", "oz", "lb" (weight), "ml", "L", "tsp", "tbsp", "fl oz", "cup", "pt", "qt", "gal" \
    (volume). Never use informal variants like "gm", "gms", "ltr", or "tbs".
    - Estimate servings when missing.
    - Estimate prep and cook times when not provided.
    - Estimate caloriesPerServing using standard nutritional knowledge of the ingredients, their \
    quantities, and the serving count. Always provide a number — only return null if the recipe \
    is fundamentally not food (this should essentially never happen).
    - Keep instructions concise, beginner-friendly and easy to follow.
    - Expand cooking shorthand into clear instructions.
    - Split instructions into logical cooking actions. Never create two steps for the same action \
    — each step must be materially different from the ones before and after it.
    - When one sentence describes multiple sequential sub-actions that each have their own stated \
    duration (for example "cook on high for 5-6 minutes, then lower the heat and cook covered for \
    10 minutes"), split it into one step per sub-action, and give each step ONLY its own duration \
    as timerSeconds. Never reuse the same duration across more than one step, sum multiple stated \
    durations into a single step's timer, or infer a timer from a neighboring step. Otherwise \
    return null.
    - Generate short step titles (3-6 words).
    - For each step, list the ingredient names used in that step, spelled EXACTLY as they appear \
    in the "name" field of the ingredients list — same casing, wording, and punctuation — so it \
    can be matched back programmatically. Never paraphrase, pluralize, or shorten an ingredient \
    name in ingredientsUsed.
    - Ignore introductions, headnotes, and unrelated text — extract only the recipe itself.
    - Classify difficulty as "easy", "medium", or "hard" for a home cook.
    - Set cuisine to the single most fitting cuisine (e.g. "Italian", "Indian", "Fusion").
    - Set mealType to every meal occasion this dish reasonably fits (e.g. ["Dinner"], \
    ["Breakfast", "Snack"]).
    - Set dietaryTags to every dietary label the finished recipe genuinely satisfies (e.g. \
    "Vegetarian", "Vegan", "Gluten-Free", "High Protein", "Dairy-Free").

    When useful, naturally include:
    - cookware
    - heat level
    - preheating
    - lid on/off
    - stirring guidance
    - visual doneness cues
    - resting instructions
    - sequencing advice between components

    Only include guidance that improves execution — set a step's cookware, heatLevel, lid, and \
    visualCue to null when they wouldn't add anything.

    Ingredients

    - Never invent ingredients for an existing recipe.
    - Mark an ingredient optional only if the source text says so (e.g. "optional", "if desired").
    - Preserve ingredient sections such as Marinade, Curry, Sauce, or Garnish. Use null if the \
    recipe has no sections.
    - Set prep to a short preparation note (e.g. "finely minced", "diced") when the ingredient \
    needs one, otherwise null.
    - Use null for unknown quantities or units.

    If generating a recipe from a dish name, cooking request, or ingredient list:
    - prefer authentic techniques
    - use commonly available ingredients
    - avoid unnecessary complexity
    - avoid niche equipment unless essential
    - produce a recipe that a home cook can confidently follow.
    """

    static let schema: [String: Any] = [
        "type": "object",
        "properties": [
            "title": ["type": "string", "description": "The recipe's title."],
            "description": ["type": ["string", "null"], "description": "A one to two sentence description of the dish."],
            "servings": ["type": "integer", "description": "Number of servings. Estimate a reasonable default if not stated."],
            "prepTimeMinutes": ["type": ["integer", "null"], "description": "Prep time in minutes, if stated or inferable."],
            "cookTimeMinutes": ["type": ["integer", "null"], "description": "Cook time in minutes, if stated or inferable."],
            "caloriesPerServing": ["type": ["integer", "null"], "description": "Estimated calories per serving."],
            "optimizationSummary": ["type": ["string", "null"], "description": "Short note on what was changed to satisfy requested optimizations, or null if none were requested."],
            "difficulty": ["type": "string", "enum": ["easy", "medium", "hard"], "description": "Difficulty for a home cook."],
            "cuisine": ["type": "string", "description": "The single most fitting cuisine, e.g. Italian, Indian, Fusion."],
            "mealType": [
                "type": "array",
                "description": "Meal occasions this dish fits, e.g. [\"Dinner\"] or [\"Breakfast\", \"Snack\"].",
                "items": ["type": "string"],
            ],
            "dietaryTags": [
                "type": "array",
                "description": "Dietary labels the recipe genuinely satisfies, e.g. Vegetarian, Vegan, Gluten-Free, High Protein.",
                "items": ["type": "string"],
            ],
            "ingredients": [
                "type": "array",
                "items": [
                    "type": "object",
                    "properties": [
                        "name": ["type": "string"],
                        "quantity": ["type": ["number", "null"]],
                        "unit": ["type": ["string", "null"]],
                        "section": ["type": ["string", "null"], "description": "Ingredient group such as Marinade, Curry, Garnish."],
                        "optional": ["type": "boolean"],
                        "prep": ["type": ["string", "null"], "description": "Short prep note such as 'finely minced' or 'diced'."],
                    ],
                    "required": ["name", "quantity", "unit", "section", "optional", "prep"],
                    "additionalProperties": false,
                ],
            ],
            "steps": [
                "type": "array",
                "items": [
                    "type": "object",
                    "properties": [
                        "stepNumber": ["type": "integer"],
                        "title": ["type": "string", "description": "A short 3-6 word step title."],
                        "instruction": ["type": "string"],
                        "ingredientsUsed": [
                            "type": "array",
                            "items": ["type": "string"],
                        ],
                        "timerSeconds": ["type": ["integer", "null"]],
                        "tips": ["type": ["string", "null"]],
                        "cookware": ["type": ["string", "null"], "description": "Cookware used in this step, if relevant."],
                        "heatLevel": ["type": ["string", "null"], "description": "Stove/oven heat level for this step, if relevant, e.g. low, medium, high."],
                        "lid": ["type": ["string", "null"], "enum": ["on", "off", NSNull()], "description": "Whether the lid should be on or off, if relevant."],
                        "visualCue": ["type": ["string", "null"], "description": "How to visually judge doneness for this step, if relevant."],
                    ],
                    "required": ["stepNumber", "title", "instruction", "ingredientsUsed", "timerSeconds", "tips", "cookware", "heatLevel", "lid", "visualCue"],
                    "additionalProperties": false,
                ],
            ],
        ],
        "required": ["title", "description", "servings", "prepTimeMinutes", "cookTimeMinutes", "caloriesPerServing", "optimizationSummary", "difficulty", "cuisine", "mealType", "dietaryTags", "ingredients", "steps"],
        "additionalProperties": false,
    ]
}
