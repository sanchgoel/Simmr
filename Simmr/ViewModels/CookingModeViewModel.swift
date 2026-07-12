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
    }

    let steps: [RecipeStep]

    @Published private(set) var currentStepIndex: Int = 0
    @Published private(set) var timerRemaining: Int = 0
    @Published private(set) var isTimerRunning: Bool = false
    @Published private(set) var isTimerComplete: Bool = false

    private var timerTask: Task<Void, Never>?
    /// Keyed by lowercased name so step ingredientsUsed strings can be matched
    /// back to the recipe's (serving-scaled) ingredients for their quantity.
    private let ingredientsByName: [String: Ingredient]

    init(steps: [RecipeStep], ingredients: [Ingredient]) {
        self.steps = steps
        self.ingredientsByName = Dictionary(
            ingredients.map { ($0.name.lowercased(), $0) },
            uniquingKeysWith: { first, _ in first }
        )
        resetTimer()
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
            let match = ingredientsByName[name.lowercased()]
            return UsedIngredient(name: match?.name ?? name, quantityLabel: match?.quantityLabel)
        }
    }

    var timerTotal: Int { currentStep.timerSeconds ?? 0 }
    var timerProgress: Double {
        guard timerTotal > 0 else { return 0 }
        return 1 - (Double(timerRemaining) / Double(timerTotal))
    }

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

    func startTimer() {
        guard currentStep.hasTimer, timerRemaining > 0, !isTimerRunning else { return }
        isTimerRunning = true

        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while let self, self.timerRemaining > 0, !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                self.timerRemaining -= 1
            }
            guard let self, !Task.isCancelled else { return }
            self.isTimerRunning = false
            if self.timerRemaining == 0 {
                self.isTimerComplete = true
            }
        }
    }

    func pauseTimer() {
        isTimerRunning = false
        timerTask?.cancel()
        timerTask = nil
    }

    func resetTimer() {
        pauseTimer()
        timerRemaining = currentStep.timerSeconds ?? 0
        isTimerComplete = false
    }
}
