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

import Foundation

enum RecipeJSONSchema {
    static let schemaName = "recipe"

    static let systemPrompt = """
    You are an expert culinary recipe parser. Convert any recipe into structured JSON.

    Rules:
    - Return valid JSON only, matching the provided schema exactly.
    - Write every output field — titles, descriptions, ingredient names, instructions, tips — in \
    English only. If the source recipe is in another language or mixes scripts (e.g. "Onion | \
    प्याज"), translate it to plain English and drop the non-English text entirely. Never output \
    bilingual or dual-script text.
    - Preserve all ingredients and their cooking order.
    - Split long instructions into logical steps; each step is a single cooking action.
    - Never create two steps for the same action. Each step must be materially different from \
    the ones before and after it — do not pad the step count by splitting one action into \
    redundant near-duplicate steps.
    - When one sentence describes multiple sequential sub-actions that each have their own \
    stated duration (for example "cook on high for 5-6 minutes, then lower the heat and cook \
    covered for 10 minutes"), split it into one step per sub-action, and give each step ONLY \
    its own duration as timerSeconds. Never reuse the same duration across more than one step, \
    and never sum multiple stated durations into a single step's timer.
    - Generate short step titles (3-6 words).
    - Extract prep time, cook time, and servings when available. Estimate servings only if missing.
    - Infer timerSeconds only when the recipe explicitly specifies a duration for that exact step's \
    action (for example "cook for 10 minutes"). Otherwise return null. Double-check that a \
    timerSeconds value matches the specific duration written for that step, not a neighboring step.
    - Preserve ingredient sections such as Marinade, Curry, Sauce, or Garnish. Use null if the \
    recipe has no sections.
    - Do not invent ingredients that aren't in the source recipe, but ALWAYS give every ingredient \
    a concrete quantity and unit — even when the source text states no amount at all (for example \
    "garam masala", "black pepper powder", or "hot water" listed with no quantity). Use your \
    culinary knowledge of the dish to estimate a sensible amount scaled to the stated servings. \
    Vague phrases like "to taste", "as needed", or "a pinch" must also become a concrete quantity \
    and unit (for example "salt to taste" becomes quantity 0.5, unit "tsp"). Only return null for \
    quantity or unit in the rare case an ingredient has no reasonable numeric equivalent at all \
    (e.g. "a few ice cubes") — this should almost never happen.
    - Mark an ingredient optional only if the source text says so (e.g. "optional", "if desired").
    - Keep instructions concise while preserving important details.
    - For each step, list the ingredient names used in that step, and spell each one EXACTLY as it \
    appears in the "name" field of the ingredients list — same casing, wording, and punctuation — \
    so it can be matched back programmatically. Never paraphrase, pluralize, or shorten an \
    ingredient name in ingredientsUsed.
    - Ignore introductions, headnotes, and unrelated text — extract only the recipe itself.
    """

    static let schema: [String: Any] = [
        "type": "object",
        "properties": [
            "title": ["type": "string", "description": "The recipe's title."],
            "description": ["type": ["string", "null"], "description": "A one to two sentence description of the dish."],
            "servings": ["type": "integer", "description": "Number of servings. Estimate a reasonable default if not stated."],
            "prepTimeMinutes": ["type": ["integer", "null"], "description": "Prep time in minutes, if stated or inferable."],
            "cookTimeMinutes": ["type": ["integer", "null"], "description": "Cook time in minutes, if stated or inferable."],
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
                    ],
                    "required": ["name", "quantity", "unit", "section", "optional"],
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
                    ],
                    "required": ["stepNumber", "title", "instruction", "ingredientsUsed", "timerSeconds", "tips"],
                    "additionalProperties": false,
                ],
            ],
        ],
        "required": ["title", "description", "servings", "prepTimeMinutes", "cookTimeMinutes", "ingredients", "steps"],
        "additionalProperties": false,
    ]
}
