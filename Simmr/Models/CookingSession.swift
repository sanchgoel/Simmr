//
//  CookingSession.swift
//  Simmr
//
//  A persisted snapshot of an in-progress or finished cook. Distinct from
//  RecipeSession (the in-memory, @Published owner of servings/ingredient
//  state used while a screen is on screen) — this is the Codable shape that
//  survives app relaunches, keyed by its own stable `id` since Recipe.id is
//  minted fresh on every decode and can't be used for persistence identity.
//

import Foundation

struct CookingSession: Codable, Identifiable, Hashable {
    let id: UUID
    var recipe: Recipe
    var currentStepIndex: Int
    var completedStepIndices: Set<Int>
    var servings: Int
    var timerEndDate: Date?
    var timerRemainingSeconds: Int
    var isTimerRunning: Bool
    var isTimerComplete: Bool
    var timerTotalOverride: Int?
    /// Which step owns the persisted timer fields above — nil if no timer
    /// has been started (or it was explicitly reset). Lets a relaunch
    /// restore the timer to its own step even if `currentStepIndex` has
    /// since moved elsewhere, matching CookingModeViewModel's in-memory
    /// behavior of never resetting a timer just because the user browsed
    /// to a different step.
    var activeTimerStepIndex: Int?
    var startedAt: Date
    var updatedAt: Date
    var status: CookingSessionStatus

    /// A version of this session ready to begin cooking again from step one
    /// — reuses the same `id`/`recipe` (so re-cooking a completed recipe
    /// updates its existing Recent Recipes row instead of creating a
    /// duplicate) but resets all progress back to a fresh start.
    func restarted() -> CookingSession {
        var copy = self
        copy.currentStepIndex = 0
        copy.completedStepIndices = []
        copy.timerEndDate = nil
        // Seed from the first step's own duration, not a flat 0 — CookingModeViewModel's
        // restore path only calls resetTimer() for a genuinely nil existingCookingSession,
        // so a fresh-but-non-nil one (this, or a newly generated recipe's .notStarted
        // session) must already carry the correct starting value itself.
        copy.timerRemainingSeconds = recipe.steps.first?.timerSeconds ?? 0
        copy.isTimerRunning = false
        copy.isTimerComplete = false
        copy.timerTotalOverride = nil
        copy.activeTimerStepIndex = nil
        let now = Date()
        copy.startedAt = now
        copy.updatedAt = now
        copy.status = .active
        return copy
    }
}

/// Decides launch-time behavior, not just a progress label — see
/// CookingSessionRestorer and CookingModeViewModel for how each is used.
enum CookingSessionStatus: String, Codable {
    /// Generated (or imported) but never started cooking — persisted purely
    /// so it shows up in Recent Recipes rather than being lost the moment
    /// the user navigates away from Overview without tapping Start Cooking.
    case notStarted
    /// Mid-cook, CookingModeView is (or was, before a force-quit) on screen
    /// without the user explicitly backing out. The only status that forces
    /// auto-navigation on the next cold launch.
    case active
    /// User backed out of Cooking Mode to Home without finishing, while the
    /// app was still running. Resumable, but doesn't force-navigate.
    case paused
    case completed
}
