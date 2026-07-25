//
//  CookingActivityAttributes.swift
//  Simmr
//
//  The ActivityKit contract for Cooking Mode's Live Activity. Compiled into
//  both the Simmr app target and the SimmrWidgetExtension target, since
//  ActivityAttributes must be the exact same type in both processes.
//
//  ContentState carries the full ordered step titles/instructions plus the
//  current index, rather than pre-computed "current/previous/next" strings.
//  That makes the Activity itself the single source of truth both processes
//  can read and mutate: the app updates it as it navigates, and the
//  Previous/Next/Finish App Intents (running in the widget extension
//  process when a Live Activity button is tapped) can recompute the next
//  state from the same array without needing any shared storage or App
//  Group entitlement — ActivityKit already keeps `Activity.activities` in
//  sync across the app and its extensions.
//

import ActivityKit
import Foundation

struct CookingActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var stepTitles: [String]
        var stepInstructions: [String]
        var currentStepIndex: Int
        /// Wall-clock moment the timer ends. Nil means no timer is running
        /// for this step. Drives `Text(timerInterval:)` in the widget so
        /// the countdown keeps ticking correctly even while the app (and
        /// this Activity's own process) is suspended.
        var timerEndDate: Date?
        var isTimerPaused: Bool
        /// Only meaningful while paused, since there's no end date to
        /// derive a live countdown from in that state.
        var pausedRemainingSeconds: Int?
        var isTimerComplete: Bool

        var totalSteps: Int { stepTitles.count }
        var stepNumber: Int { currentStepIndex + 1 }
        var stepTitle: String { stepTitles[safe: currentStepIndex] ?? "" }
        var instruction: String { stepInstructions[safe: currentStepIndex] ?? "" }
        var isFirstStep: Bool { currentStepIndex <= 0 }
        var isLastStep: Bool { currentStepIndex >= stepTitles.count - 1 }
        var previousStepTitle: String? { isFirstStep ? nil : stepTitles[safe: currentStepIndex - 1] }
        var nextStepTitle: String? { isLastStep ? nil : stepTitles[safe: currentStepIndex + 1] }
    }

    var recipeTitle: String
    /// Stable identifier for the persisted CookingSession this Activity
    /// belongs to. Fixed at Activity creation (Attributes, unlike
    /// ContentState, can't change over the Activity's lifetime) — lets a
    /// relaunched app find and re-adopt a still-running Activity instead of
    /// creating a duplicate. See LiveActivityManager.
    var sessionID: UUID
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
