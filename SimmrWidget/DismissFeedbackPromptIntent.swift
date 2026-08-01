//
//  DismissFeedbackPromptIntent.swift
//  SimmrWidget
//
//  Runs entirely in the widget extension process when tapped from the
//  finished Live Activity's "Not now" button — never opens the app. See
//  CookingSessionManager for how the running Activity stays the shared
//  source of truth.
//

import AppIntents

struct DismissFeedbackPromptIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Not Now"

    func perform() async throws -> some IntentResult {
        await CookingSessionManager.dismissFeedbackPrompt()
        return .result()
    }
}
