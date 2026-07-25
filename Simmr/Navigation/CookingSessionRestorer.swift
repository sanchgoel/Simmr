//
//  CookingSessionRestorer.swift
//  Simmr
//
//  Runs once at launch (see RootView) to answer "should this cold launch
//  land directly in Cooking Mode instead of Home?" Deliberately a free
//  function/enum rather than living on RootView itself, so the
//  reconciliation logic (persisted state vs. whatever a still-alive Live
//  Activity says) is easy to reason about and test in isolation.
//

import Foundation

struct RestoredLaunchState {
    let recipeSession: RecipeSession?
    let cookingSession: CookingSession?
    let path: [AppRoute]

    static let none = RestoredLaunchState(recipeSession: nil, cookingSession: nil, path: [])
}

@MainActor
enum CookingSessionRestorer {
    static func restore(
        repository: CookingSessionRepository? = nil
    ) async -> RestoredLaunchState {
        let repository = repository ?? LocalCookingSessionRepository()
        guard let persisted = try? await repository.fetchActiveSession() else {
            return .none
        }

        var session = persisted

        if let live = LiveActivityManager.shared.liveState(for: persisted.id) {
            // The Live Activity may be ahead of what's on disk — the user
            // could have tapped Next/Previous/Finish on it while the app
            // itself was killed, which only ActivityKit's cross-process
            // sync knows about.
            session.currentStepIndex = live.currentStepIndex
            session.timerEndDate = live.timerEndDate
            session.isTimerRunning = !live.isTimerPaused && live.timerEndDate != nil
            session.timerRemainingSeconds = live.pausedRemainingSeconds ?? session.timerRemainingSeconds
            session.isTimerComplete = live.isTimerComplete
            session.updatedAt = Date()
            try? await repository.save(session)

            let recipeSession = RecipeSession(recipe: session.recipe)
            recipeSession.servings = session.servings
            return RestoredLaunchState(recipeSession: recipeSession, cookingSession: session, path: [.cooking])
        } else {
            // No live Activity for a persisted .active session — it expired
            // naturally, or Finish was tapped on it while the app was dead
            // (the two are indistinguishable from a fresh process, and not
            // worth an App Group to disambiguate). Either way, don't force
            // the user into a session that's actually over; keep it
            // resumable from Home instead.
            session.status = .paused
            session.updatedAt = Date()
            try? await repository.save(session)
            return .none
        }
    }
}
