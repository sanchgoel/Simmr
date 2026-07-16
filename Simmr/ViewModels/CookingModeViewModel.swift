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

    let steps: [RecipeStep]

    @Published private(set) var currentStepIndex: Int = 0
    @Published private(set) var timerRemaining: Int = 0
    @Published private(set) var isTimerRunning: Bool = false
    @Published private(set) var isTimerComplete: Bool = false
    /// Flips to true when the Live Activity's "🍽 Finish Recipe" button ends
    /// the session from outside the app. CookingModeView observes this to
    /// pop back out of Cooking Mode, mirroring the in-app Finish button.
    @Published var didFinishExternally: Bool = false

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

    init(steps: [RecipeStep], ingredients: [Ingredient], recipeTitle: String) {
        self.steps = steps
        self.ingredients = ingredients
        self.recipeTitle = recipeTitle
        self.ingredientsByName = Dictionary(
            ingredients.map { ($0.name.lowercased(), $0) },
            uniquingKeysWith: { first, _ in first }
        )
        resetTimer()
        startLiveActivity()
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

    var timerTotal: Int { timerTotalOverride ?? timerFloor }
    var timerProgress: Double {
        guard timerTotal > 0 else { return 0 }
        return 1 - (Double(timerRemaining) / Double(timerTotal))
    }

    /// The recipe's originally stated duration for this step — the floor the
    /// minute stepper can never go below.
    private var timerFloor: Int { currentStep.timerSeconds ?? 0 }
    var timerTotalMinutes: Int { Int((Double(timerTotal) / 60).rounded()) }
    var timerFloorMinutes: Int { Int((Double(timerFloor) / 60).rounded()) }
    var canDecreaseTimerMinute: Bool { timerTotal > timerFloor }

    func goToNextStep() {
        guard !isLastStep else { return }
        currentStepIndex += 1
        resetTimer()
    }

    func goToPreviousStep() {
        guard !isFirstStep else { return }
        currentStepIndex -= 1
        resetTimer()
    }

    /// Called when the user finishes the recipe or leaves Cooking Mode, so
    /// the Live Activity doesn't linger after it's no longer relevant.
    func endCookingSession() {
        LiveActivityManager.shared.end()
    }

    func startTimer() {
        guard currentStep.hasTimer, timerRemaining > 0, !isTimerRunning else { return }
        isTimerRunning = true
        timerEndDate = Date().addingTimeInterval(TimeInterval(timerRemaining))
        syncLiveActivity()

        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                self.syncTimerToWallClock()
                if self.timerRemaining <= 0 { return }
            }
        }
    }

    func pauseTimer() {
        isTimerRunning = false
        timerTask?.cancel()
        timerTask = nil
        timerEndDate = nil
        syncLiveActivity()
    }

    func resetTimer() {
        pauseTimer()
        timerTotalOverride = nil
        timerRemaining = currentStep.timerSeconds ?? 0
        isTimerComplete = false
        syncLiveActivity()
    }

    /// Increases the configured timer duration by one minute — works whether
    /// the timer is idle, running, or already finished. Tap repeatedly to
    /// add more.
    func incrementTimerMinute() {
        guard currentStep.hasTimer else { return }
        timerTotalOverride = timerTotal + 60
        timerRemaining += 60
        isTimerComplete = false
        if isTimerRunning, let timerEndDate {
            self.timerEndDate = timerEndDate.addingTimeInterval(60)
        }
        syncLiveActivity()
    }

    /// Decreases the configured timer duration by one minute, down to (but
    /// never below) the recipe's originally stated duration for this step.
    func decrementTimerMinute() {
        guard currentStep.hasTimer, canDecreaseTimerMinute else { return }
        timerTotalOverride = timerTotal - 60
        timerRemaining = max(0, timerRemaining - 60)
        defer { syncLiveActivity() }
        guard isTimerRunning else { return }
        if timerRemaining == 0 {
            isTimerRunning = false
            isTimerComplete = true
            timerEndDate = nil
            timerTask?.cancel()
            timerTask = nil
        } else if let timerEndDate {
            self.timerEndDate = timerEndDate.addingTimeInterval(-60)
        }
    }

    /// Recomputes timerRemaining from the wall-clock end date instead of
    /// trusting the tick count, so time spent backgrounded (where this
    /// task's sleep doesn't run) is still accounted for the moment the app
    /// resumes.
    private func syncTimerToWallClock() {
        guard let timerEndDate else { return }
        let remaining = Int(ceil(timerEndDate.timeIntervalSinceNow))
        if remaining <= 0 {
            timerRemaining = 0
            isTimerRunning = false
            isTimerComplete = true
            self.timerEndDate = nil
            timerTask?.cancel()
            timerTask = nil
            // Only the completion transition needs to push a Live Activity
            // update — the countdown itself is rendered by the widget via
            // Text(timerInterval:), so there's no need to update every tick.
            syncLiveActivity()
        } else {
            timerRemaining = remaining
        }
    }

    /// Called when the app returns to the foreground so the displayed time
    /// is correct immediately, without waiting for the next 1-second tick.
    func refreshTimerIfNeeded() {
        guard isTimerRunning else { return }
        syncTimerToWallClock()
    }

    private func startLiveActivity() {
        LiveActivityManager.shared.onExternalStepChange = { [weak self] newIndex in
            self?.applyExternalStepChange(newIndex)
        }
        LiveActivityManager.shared.onActivityEndedExternally = { [weak self] in
            self?.didFinishExternally = true
        }
        LiveActivityManager.shared.start(
            recipeTitle: recipeTitle,
            stepTitles: steps.map(\.title),
            stepInstructions: steps.map(\.instruction),
            currentStepIndex: currentStepIndex
        )
    }

    /// Pushes the Live Activity's content in sync with the view model's own
    /// state. Called on every step change and every timer state transition
    /// (start/pause/resume/adjust/complete) — never on a per-second tick,
    /// since the widget renders the live countdown itself.
    private func syncLiveActivity() {
        LiveActivityManager.shared.update(
            currentStepIndex: currentStepIndex,
            timerEndDate: isTimerRunning ? timerEndDate : nil,
            isTimerPaused: isTimerPaused,
            pausedRemainingSeconds: isTimerPaused ? timerRemaining : nil,
            isTimerComplete: isTimerComplete
        )
    }

    /// Applies a step change made from the Live Activity's Previous/Next
    /// buttons (which run in the widget extension process and update the
    /// Activity directly) so the in-app UI reflects it immediately.
    private func applyExternalStepChange(_ newIndex: Int) {
        guard newIndex != currentStepIndex, steps.indices.contains(newIndex) else { return }
        currentStepIndex = newIndex
        resetTimer()
    }

    private var isTimerPaused: Bool {
        currentStep.hasTimer && !isTimerRunning && !isTimerComplete && timerRemaining > 0
    }
}
