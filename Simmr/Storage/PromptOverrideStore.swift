//
//  PromptOverrideStore.swift
//  Simmr
//
//  Lets the recipe system prompt be edited from Settings for testing,
//  without shipping a code change. RecipeParserService uses the saved
//  override in place of RecipeJSONSchema.defaultSystemPrompt whenever one
//  is present.
//

import Foundation

protocol PromptOverrideStoring {
    func load() -> String?
    func save(_ prompt: String?)
}

final class UserDefaultsPromptOverrideStore: PromptOverrideStoring {
    private let key = "com.inspiredevstudio.Simmr.recipeSystemPromptOverride"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> String? {
        defaults.string(forKey: key)
    }

    /// Saving an empty/whitespace-only prompt clears the override, reverting to the default.
    func save(_ prompt: String?) {
        let trimmed = prompt?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed, !trimmed.isEmpty else {
            defaults.removeObject(forKey: key)
            return
        }
        defaults.set(trimmed, forKey: key)
    }
}
