//
//  CookingModeViewModel.swift
//  Simmr
//

import Combine
import Foundation

@MainActor
final class CookingModeViewModel: ObservableObject {
    struct UsedIngredient: Identifiable {
        let id = UUID()
        let name: String
        let quantityLabel: String?
        let quantity: Double?
        let unit: String?
    }

    /// Tracks whether this cook has already reached Finish, so a
    /// Finish -> pop -> onDisappear sequence can't downgrade a completed
    /// session back to paused regardless of call ordering.
    private enum SessionLifecycle {
        case cooking
        case completed
    }

    let recipe: Recipe
    let steps: [RecipeStep]
    let servings: Int
    let sessionID: UUID
    let startedAt: Date

    @Published private(set) var currentStepIndex: Int = 0
    /// Which step "owns" the one active cooking timer — nil if no timer has
    /// been started (or it was explicitly reset) since this session began.
    /// Navigating to a different step never touches this: the active timer
    /// keeps counting on its own step while whichever step is currently on
    /// screen shows its own idle default, so stepping away and back always
    /// restores the exact state instead of resetting it.
    @Published private(set) var activeTimerStepIndex: Int?
    @Published private(set) var activeTimerRemaining: Int = 0
    @Published private(set) var isActiveTimerRunning: Bool = false
    @Published private(set) var isActiveTimerComplete: Bool = false
    /// Flips to true when the Live Activity's "🍽 Finish Recipe" button ends
    /// the session from outside the app. CookingModeView observes this to
    /// pop back out of Cooking Mode, mirroring the in-app Finish button.
    @Published var didFinishExternally: Bool = false

    private var completedStepIndices: Set<Int>
    private var sessionState: SessionLifecycle = .cooking
    private var timerTask: Task<Void, Never>?
    /// Wall-clock moment the timer should hit zero. Remaining time is always
    /// recomputed from this rather than decremented tick-by-tick, so the
    /// countdown stays accurate even after the app is suspended in the
    /// background (where the sleep-based loop below doesn't get CPU time).
    private var timerEndDate: Date?
    /// Total duration for the current timer, adjustable via addOneMinute()
    /// so the progress ring stays consistent after time is added.
    private var timerTotalOverride: Int?
    /// Keyed by lowercased name so step ingredientsUsed strings can be matched
    /// back to the recipe's (serving-scaled) ingredients for their quantity.
    private let ingredientsByName: [String: Ingredient]
    /// Fallback list for fuzzy matching when a step's ingredientsUsed string
    /// doesn't exactly match an ingredient name (e.g. pluralization drift).
    private let ingredients: [Ingredient]
    private let recipeTitle: String
    private let cookingSessionRepository: CookingSessionRepository

    /// `existingCookingSession` nil means "start cooking fresh" (mints a new
    /// sessionID/startedAt, timer starts idle at the first step's stated
    /// duration). Non-nil means "resume" — reuses the persisted id/timestamps
    /// and restores step/timer state exactly, including resuming a timer
    /// that was still running when the app was last alive.
    init(
        recipe: Recipe,
        ingredients: [Ingredient],
        servings: Int,
        existingCookingSession: CookingSession? = nil,
        cookingSessionRepository: CookingSessionRepository? = nil
    ) {
        self.recipe = recipe
        self.steps = recipe.steps
        self.recipeTitle = recipe.title
        self.ingredients = ingredients
        self.servings = servings
        self.ingredientsByName = Dictionary(
            ingredients.map { ($0.name.lowercased(), $0) },
            uniquingKeysWith: { first, _ in first }
        )
        self.cookingSessionRepository = cookingSessionRepository ?? LocalCookingSessionRepository()

        if let existingCookingSession {
            sessionID = existingCookingSession.id
            startedAt = existingCookingSession.startedAt
            completedStepIndices = existingCookingSession.completedStepIndices
            currentStepIndex = max(0, min(existingCookingSession.currentStepIndex, max(recipe.steps.count - 1, 0)))
            timerTotalOverride = existingCookingSession.timerTotalOverride

            // Older persisted sessions (saved before activeTimerStepIndex
            // existed) don't carry it — fall back to inferring ownership
            // from whether the timer fields look touched at all.
            let restoredFloor = recipe.steps[currentStepIndex].timerSeconds ?? 0
            let wasTouched = existingCookingSession.isTimerRunning
                || existingCookingSession.isTimerComplete
                || existingCookingSession.timerRemainingSeconds != restoredFloor
            activeTimerStepIndex = existingCookingSession.activeTimerStepIndex ?? (wasTouched ? currentStepIndex : nil)

            if existingCookingSession.isTimerRunning, let restoredEndDate = existingCookingSession.timerEndDate {
                let remaining = Int(ceil(restoredEndDate.timeIntervalSinceNow))
                if remaining > 0 {
                    timerEndDate = restoredEndDate
                    activeTimerRemaining = remaining
                    isActiveTimerRunning = true
                    isActiveTimerComplete = false
                } else {
                    timerEndDate = nil
                    activeTimerRemaining = 0
                    isActiveTimerRunning = false
                    isActiveTimerComplete = true
                }
            } else {
                timerEndDate = nil
                activeTimerRemaining = existingCookingSession.timerRemainingSeconds
                isActiveTimerRunning = false
                isActiveTimerComplete = existingCookingSession.isTimerComplete
            }
        } else {
            sessionID = UUID()
            startedAt = Date()
            completedStepIndices = []
            currentStepIndex = 0
        }

        if existingCookingSession == nil {
            resetTimer()
        } else if isActiveTimerRunning {
            resumeTicking()
        }

        startLiveActivity()
        persistSnapshot(status: .active)
    }

    var currentStep: RecipeStep { steps[currentStepIndex] }
    var stepNumber: Int { currentStepIndex + 1 }
    var totalSteps: Int { steps.count }
    var progress: Double { Double(stepNumber) / Double(max(totalSteps, 1)) }
    var isFirstStep: Bool { currentStepIndex == 0 }
    var isLastStep: Bool { currentStepIndex == totalSteps - 1 }

    /// Ingredients used in the current step, resolved against the scaled recipe
    /// ingredients so each chip can show exactly how much to add right now.
    var currentStepIngredients: [UsedIngredient] {
        currentStep.ingredientsUsed.map { name in
            let match = resolveIngredient(named: name)
            return UsedIngredient(
                name: match?.name ?? name,
                quantityLabel: match?.quantityLabel,
                quantity: match?.quantity,
                unit: match?.unit
            )
        }
    }

    /// Resolves a step's ingredientsUsed string back to a recipe ingredient.
    /// Tries an exact (case-insensitive) match first, then falls back to a
    /// substring match so minor wording drift (e.g. "onion" vs "onions")
    /// still surfaces a quantity instead of leaving the chip blank.
    private func resolveIngredient(named name: String) -> Ingredient? {
        let normalized = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if let exact = ingredientsByName[normalized] {
            return exact
        }
        return ingredients.first { ingredient in
            let ingredientName = ingredient.name.lowercased()
            return ingredientName.contains(normalized) || normalized.contains(ingredientName)
        }
    }

    /// True only when the step currently on screen is the one that owns the
    /// active timer — the sole condition under which the real, ticking
    /// timer state should be displayed. Any other step shows its own
    /// untouched idle default instead, without disturbing the active timer
    /// counting down elsewhere.
    private var isActiveStepDisplayed: Bool { activeTimerStepIndex == currentStepIndex }

    var timerRemaining: Int { isActiveStepDisplayed ? activeTimerRemaining : (currentStep.timerSeconds ?? 0) }
    var isTimerRunning: Bool { isActiveStepDisplayed && isActiveTimerRunning }
    var isTimerComplete: Bool { isActiveStepDisplayed && isActiveTimerComplete }

    var timerTotal: Int { isActiveStepDisplayed ? (timerTotalOverride ?? timerFloor) : timerFloor }
    var timerProgress: Double {
        guard timerTotal > 0 else { return 0 }
        return 1 - (Double(timerRemaining) / Double(timerTotal))
    }

    /// The recipe's stated duration for this step — the idle/reset default,
    /// but not a floor on how low the stepper can go (see
    /// `timerMinimumSeconds`, which lets any step be dialed down to 1
    /// minute regardless of its suggested duration).
    private var timerFloor: Int { currentStep.timerSeconds ?? 0 }
    /// Absolute lower bound for the minute stepper.
    private let timerMinimumSeconds = 60
    var canDecreaseTimerMinute: Bool { timerTotal > timerMinimumSeconds }

    func goToNextStep() {
        guard !isLastStep else { return }
        completedStepIndices.insert(currentStepIndex)
        currentStepIndex += 1
        syncLiveActivity()
        persistSnapshot(status: .active)
    }

    func goToPreviousStep() {
        guard !isFirstStep else { return }
        currentStepIndex -= 1
        syncLiveActivity()
        persistSnapshot(status: .active)
    }

    /// Marks the cook as finished — called from the in-app Finish button.
    /// Guarded by sessionState so it's a no-op if somehow called twice.
    func finishCooking() {
        guard sessionState == .cooking else { return }
        completedStepIndices.insert(currentStepIndex)
        sessionState = .completed
        persistSnapshot(status: .completed)
        LiveActivityManager.shared.end()
    }

    /// Called when the user leaves Cooking Mode via any pop — back-swipe, or
    /// after finishCooking() already ran and popped the nav stack. If the
    /// session never reached `.completed`, this means the user backed out
    /// without finishing, so it's persisted `.paused` (still resumable, but
    /// won't force-navigate on the next launch). The sessionState guard is
    /// what makes a Finish -> pop -> onDisappear sequence safe regardless of
    /// ordering — it won't downgrade an already-completed session.
    func endCookingSession() {
        if sessionState == .cooking {
            persistSnapshot(status: .paused)
        }
        LiveActivityManager.shared.end()
    }

    /// If a different, not-yet-claimed step is on screen, this claims it as
    /// the one active timer, seeded fresh from its own stated duration —
    /// shared by startTimer() and incrementTimerMinute(), the two ways a
    /// step can go from "someone else's turn" to "this is now the active
    /// timer."
    private func claimActiveTimerIfNeeded() {
        guard !isActiveStepDisplayed else { return }
        activeTimerStepIndex = currentStepIndex
        timerTotalOverride = nil
        activeTimerRemaining = currentStep.timerSeconds ?? 0
        isActiveTimerComplete = false
    }

    func startTimer() {
        guard currentStep.hasTimer, timerRemaining > 0, !isTimerRunning else { return }
        claimActiveTimerIfNeeded()
        isActiveTimerRunning = true
        timerEndDate = Date().addingTimeInterval(TimeInterval(activeTimerRemaining))
        syncLiveActivity()
        resumeTicking()
        persistSnapshot(status: .active)
    }

    func pauseTimer() {
        isActiveTimerRunning = false
        timerTask?.cancel()
        timerTask = nil
        timerEndDate = nil
        syncLiveActivity()
        persistSnapshot(status: .active)
    }

    /// Relinquishes ownership of the active timer entirely (not just for
    /// whichever step happens to be displayed) — the only mutator that
    /// clears `activeTimerStepIndex`, since every other one only makes
    /// sense once a step already owns the timer.
    func resetTimer() {
        pauseTimer()
        activeTimerStepIndex = nil
        timerTotalOverride = nil
        activeTimerRemaining = currentStep.timerSeconds ?? 0
        isActiveTimerComplete = false
        syncLiveActivity()
        persistSnapshot(status: .active)
    }

    /// Increases the configured timer duration by one minute — works whether
    /// the timer is idle, running, or already finished. Tap repeatedly to
    /// add more.
    func incrementTimerMinute() {
        guard currentStep.hasTimer else { return }
        claimActiveTimerIfNeeded()
        timerTotalOverride = timerTotal + 60
        activeTimerRemaining += 60
        isActiveTimerComplete = false
        if isActiveTimerRunning, let timerEndDate {
            self.timerEndDate = timerEndDate.addingTimeInterval(60)
        }
        syncLiveActivity()
        persistSnapshot(status: .active)
    }

    /// Decreases the configured timer duration by one minute, down to (but
    /// never below) 1 minute — works whether idle, running, or paused, and
    /// claims the step first if it hasn't been touched yet, exactly like
    /// incrementTimerMinute().
    func decrementTimerMinute() {
        guard currentStep.hasTimer, canDecreaseTimerMinute else { return }
        claimActiveTimerIfNeeded()
        timerTotalOverride = max(timerMinimumSeconds, timerTotal - 60)
        activeTimerRemaining = max(timerMinimumSeconds, activeTimerRemaining - 60)
        if isActiveTimerRunning, let timerEndDate {
            self.timerEndDate = timerEndDate.addingTimeInterval(-60)
        }
        syncLiveActivity()
        persistSnapshot(status: .active)
    }

    /// Recomputes activeTimerRemaining from the wall-clock end date instead
    /// of trusting the tick count, so time spent backgrounded (where this
    /// task's sleep doesn't run) is still accounted for the moment the app
    /// resumes.
    private func syncTimerToWallClock() {
        guard let timerEndDate else { return }
        let remaining = Int(ceil(timerEndDate.timeIntervalSinceNow))
        if remaining <= 0 {
            activeTimerRemaining = 0
            isActiveTimerRunning = false
            isActiveTimerComplete = true
            self.timerEndDate = nil
            timerTask?.cancel()
            timerTask = nil
            // Only the completion transition needs to push a Live Activity
            // update — the countdown itself is rendered by the widget via
            // Text(timerInterval:), so there's no need to update every tick.
            syncLiveActivity()
            persistSnapshot(status: .active)
        } else {
            activeTimerRemaining = remaining
        }
    }

    /// Called when the app returns to the foreground so the displayed time
    /// is correct immediately, without waiting for the next 1-second tick.
    func refreshTimerIfNeeded() {
        guard isActiveTimerRunning else { return }
        syncTimerToWallClock()
    }

    /// The 1-second polling loop that keeps `activeTimerRemaining` accurate
    /// while a timer runs. Shared by startTimer() (fresh start) and init's
    /// resume path (a restored session whose timer was still running) — the
    /// loop itself doesn't care which one kicked it off, only that
    /// timerEndDate is already set.
    private func resumeTicking() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                self.syncTimerToWallClock()
                if self.activeTimerRemaining <= 0 { return }
            }
        }
    }

    private func startLiveActivity() {
        LiveActivityManager.shared.onExternalStepChange = { [weak self] newIndex in
            self?.applyExternalStepChange(newIndex)
        }
        LiveActivityManager.shared.onActivityEndedExternally = { [weak self] in
            self?.applyExternalFinish()
        }
        LiveActivityManager.shared.start(
            sessionID: sessionID,
            recipeTitle: recipeTitle,
            stepTitles: steps.map(\.title),
            stepInstructions: steps.map(\.instruction),
            currentStepIndex: currentStepIndex,
            timerEndDate: isActiveTimerRunning ? timerEndDate : nil,
            isTimerPaused: isActiveTimerPaused,
            pausedRemainingSeconds: isActiveTimerPaused ? activeTimerRemaining : nil,
            isTimerComplete: isActiveTimerComplete
        )
    }

    /// Pushes the Live Activity's content in sync with the view model's own
    /// state. Called on every step change and every timer state transition
    /// (start/pause/resume/adjust/complete) — never on a per-second tick,
    /// since the widget renders the live countdown itself.
    private func syncLiveActivity() {
        LiveActivityManager.shared.update(
            currentStepIndex: currentStepIndex,
            timerEndDate: isActiveTimerRunning ? timerEndDate : nil,
            isTimerPaused: isActiveTimerPaused,
            pausedRemainingSeconds: isActiveTimerPaused ? activeTimerRemaining : nil,
            isTimerComplete: isActiveTimerComplete
        )
    }

    /// Applies a step change made from the Live Activity's Previous/Next
    /// buttons (which run in the widget extension process and update the
    /// Activity directly) so the in-app UI reflects it immediately. Doesn't
    /// touch the active timer — same "navigating steps never resets it" rule
    /// as goToNextStep()/goToPreviousStep().
    private func applyExternalStepChange(_ newIndex: Int) {
        guard newIndex != currentStepIndex, steps.indices.contains(newIndex) else { return }
        currentStepIndex = newIndex
        syncLiveActivity()
        persistSnapshot(status: .active)
    }

    /// Mirrors finishCooking() for the case where the Live Activity's own
    /// "🍽 Finish Recipe" button ended the session from outside the app —
    /// the Activity has already ended itself, so this only needs to update
    /// our own state and the persisted session, not call
    /// LiveActivityManager.shared.end() again.
    private func applyExternalFinish() {
        guard sessionState == .cooking else { return }
        completedStepIndices.insert(currentStepIndex)
        sessionState = .completed
        persistSnapshot(status: .completed)
        didFinishExternally = true
    }

    private var isActiveTimerPaused: Bool {
        activeTimerStepIndex != nil && !isActiveTimerRunning && !isActiveTimerComplete && activeTimerRemaining > 0
    }

    private func persistSnapshot(status: CookingSessionStatus) {
        let session = CookingSession(
            id: sessionID,
            recipe: recipe,
            currentStepIndex: currentStepIndex,
            completedStepIndices: completedStepIndices,
            servings: servings,
            timerEndDate: isActiveTimerRunning ? timerEndDate : nil,
            timerRemainingSeconds: activeTimerRemaining,
            isTimerRunning: isActiveTimerRunning,
            isTimerComplete: isActiveTimerComplete,
            timerTotalOverride: timerTotalOverride,
            activeTimerStepIndex: activeTimerStepIndex,
            startedAt: startedAt,
            updatedAt: Date(),
            status: status
        )
        let repository = cookingSessionRepository
        Task {
            try? await repository.save(session)
        }
    }
}
