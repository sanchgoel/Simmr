//
//  CookingSessionManager.swift
//  Simmr
//
//  Cross-process coordinator for Cooking Mode's Live Activity step
//  navigation. Compiled into both the Simmr app target and the
//  SimmrWidgetExtension target.
//
//  The running Activity's own ContentState is the single source of truth —
//  both processes read/write it directly via ActivityKit, which already
//  keeps `Activity.activities` in sync across the app and its extensions.
//  That means the Previous/Next/Finish App Intents (executed in the widget
//  extension process when a Live Activity button is tapped, without opening
//  the app) can advance the step or end the session without any App Group
//  or shared storage.
//

import ActivityKit
import Foundation

@MainActor
enum CookingSessionManager {
    /// Moves the running Activity's current step by `delta` (+1/-1),
    /// clamped to the step range, and clears any in-flight timer — mirroring
    /// what `CookingModeViewModel.resetTimer()` does for in-app navigation.
    static func advanceStep(by delta: Int) async {
        guard let activity = Activity<CookingActivityAttributes>.activities.first else { return }
        var state = activity.content.state
        let newIndex = min(max(state.currentStepIndex + delta, 0), max(state.stepTitles.count - 1, 0))
        guard newIndex != state.currentStepIndex else { return }

        state.currentStepIndex = newIndex
        state.timerEndDate = nil
        state.isTimerPaused = false
        state.pausedRemainingSeconds = nil
        state.isTimerComplete = false

        await activity.update(ActivityContent(state: state, staleDate: nil))
    }

    /// Ends the running Activity — invoked by the "🍽 Finish Recipe" button
    /// on the final step.
    static func finishRecipe() async {
        guard let activity = Activity<CookingActivityAttributes>.activities.first else { return }
        await activity.end(nil, dismissalPolicy: .immediate)
    }
}
