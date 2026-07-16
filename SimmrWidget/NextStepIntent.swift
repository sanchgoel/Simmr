//
//  NextStepIntent.swift
//  SimmrWidget
//
//  Runs entirely in the widget extension process when tapped from the Live
//  Activity — never opens the app. See CookingSessionManager for how the
//  running Activity stays the shared source of truth.
//

import AppIntents

struct NextStepIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Next Step"

    func perform() async throws -> some IntentResult {
        await CookingSessionManager.advanceStep(by: 1)
        return .result()
    }
}
