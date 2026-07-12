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
    - Preserve all ingredients and their cooking order.
    - Split long instructions into logical steps; each step is a single cooking action.
    - Generate short step titles (3-6 words).
    - Extract prep time, cook time, and servings when available. Estimate servings only if missing.
    - Infer timerSeconds only when the recipe explicitly specifies a duration (for example \
    "cook for 10 minutes"). Otherwise return null.
    - Preserve ingredient sections such as Marinade, Curry, Sauce, or Garnish. Use null if the \
    recipe has no sections.
    - Do not invent ingredients or quantities. Use null for a quantity or unit you cannot determine.
    - Mark an ingredient optional only if the source text says so (e.g. "optional", "if desired").
    - Keep instructions concise while preserving important details.
    - For each step, list the ingredient names (as they appear in the ingredients list) used in \
    that step.
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
