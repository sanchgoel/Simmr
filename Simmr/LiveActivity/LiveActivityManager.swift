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

/// Plain, non-ActivityKit snapshot of a running Activity's current content —
/// keeps ActivityKit itself contained to this one file, matching the header
/// comment above. Used by CookingSessionRestorer to reconcile a persisted
/// CookingSession against whatever a still-alive Live Activity says (which
/// may be ahead, if the user tapped Next/Previous/Finish on the Live
/// Activity while the app itself was killed).
struct LiveActivityRestoredState {
    let currentStepIndex: Int
    let timerEndDate: Date?
    let isTimerPaused: Bool
    let pausedRemainingSeconds: Int?
    let isTimerComplete: Bool
}

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

    /// Starts a Live Activity for `sessionID`, or re-adopts one that's
    /// already running (e.g. the app was force-quit mid-cook and just
    /// relaunched) rather than creating a duplicate — Activity.activities is
    /// kept in sync by ActivityKit independent of the app process, the same
    /// idiom Shared/CookingSessionManager.swift already relies on from the
    /// widget extension side. The timer-state parameters default to "no
    /// timer running," matching a fresh cook; a resumed cook passes its
    /// restored state so the Activity reflects it immediately.
    func start(
        sessionID: UUID,
        recipeTitle: String,
        stepTitles: [String],
        stepInstructions: [String],
        currentStepIndex: Int,
        timerEndDate: Date? = nil,
        isTimerPaused: Bool = false,
        pausedRemainingSeconds: Int? = nil,
        isTimerComplete: Bool = false
    ) {
        guard activity == nil else { return }

        self.stepTitles = stepTitles
        self.stepInstructions = stepInstructions

        let state = CookingActivityAttributes.ContentState(
            stepTitles: stepTitles,
            stepInstructions: stepInstructions,
            currentStepIndex: currentStepIndex,
            timerEndDate: timerEndDate,
            isTimerPaused: isTimerPaused,
            pausedRemainingSeconds: pausedRemainingSeconds,
            isTimerComplete: isTimerComplete
        )

        if let existing = Activity<CookingActivityAttributes>.activities.first(where: { $0.attributes.sessionID == sessionID }) {
            activity = existing
            observeExternalChanges(on: existing)
            Task {
                await existing.update(ActivityContent(state: state, staleDate: nil))
            }
            return
        }

        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = CookingActivityAttributes(recipeTitle: recipeTitle, sessionID: sessionID)

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

    /// Reads a still-running Activity's current content without starting or
    /// adopting it into `self.activity` — used only by CookingSessionRestorer
    /// at launch, before any CookingModeViewModel exists to own it.
    func liveState(for sessionID: UUID) -> LiveActivityRestoredState? {
        guard let match = Activity<CookingActivityAttributes>.activities.first(where: { $0.attributes.sessionID == sessionID }) else {
            return nil
        }
        let state = match.content.state
        return LiveActivityRestoredState(
            currentStepIndex: state.currentStepIndex,
            timerEndDate: state.timerEndDate,
            isTimerPaused: state.isTimerPaused,
            pausedRemainingSeconds: state.pausedRemainingSeconds,
            isTimerComplete: state.isTimerComplete
        )
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
