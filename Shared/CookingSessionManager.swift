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
import OSLog

private let logger = Logger(subsystem: "com.inspiredevstudio.simmr", category: "CookingSessionManager")

@MainActor
enum CookingSessionManager {
    /// Moves the running Activity's current step by `delta` (+1/-1), clamped
    /// to the step range. Deliberately leaves any in-flight timer alone —
    /// navigating steps (in-app or via these Live Activity buttons) never
    /// pauses or resets the one active cooking timer, mirroring
    /// `CookingModeViewModel.goToNextStep()`/`goToPreviousStep()`.
    static func advanceStep(by delta: Int) async {
        let all = Activity<CookingActivityAttributes>.activities
        logger.log("advanceStep(by: \(delta)) — activities.count = \(all.count)")
        guard let activity = all.first else {
            logger.log("advanceStep: no activities found, bailing out")
            return
        }
        var state = activity.content.state
        let newIndex = min(max(state.currentStepIndex + delta, 0), max(state.stepTitles.count - 1, 0))
        logger.log("advanceStep: currentStepIndex=\(state.currentStepIndex) -> newIndex=\(newIndex), activityID=\(activity.id, privacy: .public)")
        guard newIndex != state.currentStepIndex else {
            logger.log("advanceStep: newIndex == currentStepIndex, no-op")
            return
        }

        state.currentStepIndex = newIndex

        await activity.update(ActivityContent(state: state, staleDate: nil))
        logger.log("advanceStep: update() call completed")
    }

    /// Ends the running Activity — invoked by the "🍽 Finish Recipe" button
    /// on the final step.
    static func finishRecipe() async {
        guard let activity = Activity<CookingActivityAttributes>.activities.first else { return }
        await activity.end(nil, dismissalPolicy: .immediate)
    }
}
