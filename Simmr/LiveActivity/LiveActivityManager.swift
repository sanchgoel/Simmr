//
//  LiveActivityManager.swift
//  Simmr
//
//  Owns the Cooking Mode Live Activity end to end. This is the only file in
//  the app target that imports ActivityKit — CookingModeViewModel calls
//  plain methods here and never touches Activity/ActivityContent directly,
//  so the cooking UI stays decoupled from the ActivityKit API surface.
//
//  Everything is local (no push updates): the app calls update() at the
//  same moments it already mutates its own @Published state, and the
//  widget renders the live countdown itself via Text(timerInterval:), so
//  there's no need to tick this every second — only on real state changes.
//
//  Step navigation can also happen from the Live Activity's own Previous/
//  Next/Finish buttons, which run their App Intents in the widget extension
//  process and update the Activity directly (see CookingSessionManager) —
//  never touching the app. To reflect those taps back into the app's own
//  UI immediately, this manager observes the Activity's own content and
//  state updates (ActivityKit keeps `Activity` in sync across processes)
//  and forwards them through plain closures, keeping ActivityKit itself
//  out of CookingModeViewModel.
//

import ActivityKit
import Foundation

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var activity: Activity<CookingActivityAttributes>?
    private var stepTitles: [String] = []
    private var stepInstructions: [String] = []
    private var contentObservationTask: Task<Void, Never>?
    private var stateObservationTask: Task<Void, Never>?

    /// Fired when the current step index changes from outside the app (a
    /// Live Activity Previous/Next tap). The new index is already clamped
    /// to a valid range.
    var onExternalStepChange: ((Int) -> Void)?
    /// Fired when the Activity ends from outside the app (a Live Activity
    /// "Finish Recipe" tap).
    var onActivityEndedExternally: (() -> Void)?

    private init() {}

    func start(
        recipeTitle: String,
        stepTitles: [String],
        stepInstructions: [String],
        currentStepIndex: Int
    ) {
        guard activity == nil else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        self.stepTitles = stepTitles
        self.stepInstructions = stepInstructions

        let attributes = CookingActivityAttributes(recipeTitle: recipeTitle)
        let state = CookingActivityAttributes.ContentState(
            stepTitles: stepTitles,
            stepInstructions: stepInstructions,
            currentStepIndex: currentStepIndex,
            timerEndDate: nil,
            isTimerPaused: false,
            pausedRemainingSeconds: nil,
            isTimerComplete: false
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: nil)
            )
            self.activity = activity
            observeExternalChanges(on: activity)
        } catch {
            activity = nil
        }
    }

    func update(
        currentStepIndex: Int,
        timerEndDate: Date?,
        isTimerPaused: Bool,
        pausedRemainingSeconds: Int?,
        isTimerComplete: Bool
    ) {
        guard let activity else { return }

        let state = CookingActivityAttributes.ContentState(
            stepTitles: stepTitles,
            stepInstructions: stepInstructions,
            currentStepIndex: currentStepIndex,
            timerEndDate: timerEndDate,
            isTimerPaused: isTimerPaused,
            pausedRemainingSeconds: pausedRemainingSeconds,
            isTimerComplete: isTimerComplete
        )

        Task {
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    func end() {
        contentObservationTask?.cancel()
        contentObservationTask = nil
        stateObservationTask?.cancel()
        stateObservationTask = nil

        guard let activity else { return }
        self.activity = nil
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    private func observeExternalChanges(on activity: Activity<CookingActivityAttributes>) {
        contentObservationTask = Task { [weak self] in
            for await content in activity.contentUpdates {
                guard let self else { return }
                let newIndex = content.state.currentStepIndex
                self.onExternalStepChange?(newIndex)
            }
        }

        stateObservationTask = Task { [weak self] in
            for await state in activity.activityStateUpdates {
                guard let self else { return }
                if state == .ended || state == .dismissed {
                    self.activity = nil
                    self.onActivityEndedExternally?()
                    return
                }
            }
        }
    }
}
