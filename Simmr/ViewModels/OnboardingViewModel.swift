//
//  OnboardingViewModel.swift
//  Simmr
//

import Combine
import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    enum Screen: Equatable {
        case welcome
        case question(Int)
        case final
    }

    @Published private(set) var answers: OnboardingAnswers
    @Published var screen: Screen

    let allQuestions: [OnboardingQuestion]
    /// True when editing an already-completed profile from Settings, as
    /// opposed to first-time onboarding. Skips the welcome screen, keeps
    /// the profile marked complete while editing (so it doesn't drop back
    /// out of BackendRecipeService's personalization), and shows a close
    /// button so the user isn't forced through the remaining questions.
    let isEditing: Bool
    private let store: KitchenProfileStoring
    let onComplete: () -> Void

    init(
        allQuestions: [OnboardingQuestion] = OnboardingQuestions.all,
        store: KitchenProfileStoring? = nil,
        isEditing: Bool = false,
        onComplete: @escaping () -> Void
    ) {
        let store = store ?? UserDefaultsKitchenProfileStore()
        self.allQuestions = allQuestions
        self.store = store
        self.answers = store.load()?.answers ?? [:]
        self.isEditing = isEditing
        self.onComplete = onComplete

        if isEditing {
            let visible = allQuestions.filter { $0.isVisible(store.load()?.answers ?? [:]) }
            self.screen = visible.isEmpty ? .final : .question(0)
        } else {
            self.screen = .welcome
        }
    }

    /// Questions currently in the flow, re-filtered live as conditional answers change.
    var visibleQuestions: [OnboardingQuestion] {
        allQuestions.filter { $0.isVisible(answers) }
    }

    var showsProgressBar: Bool {
        if case .question = screen { return true }
        return false
    }

    var progress: Double {
        guard case .question(let index) = screen else { return 0 }
        return Double(index + 1) / Double(max(visibleQuestions.count, 1))
    }

    func goNext() {
        guard case .question(let index) = screen else { return }
        let questions = visibleQuestions
        let next = index + 1
        if next < questions.count {
            screen = .question(next)
        } else {
            completeOnboarding()
        }
    }

    func goBack() {
        switch screen {
        case .question(let index):
            if index == 0 {
                isEditing ? close() : (screen = .welcome)
            } else {
                screen = .question(index - 1)
            }
        case .final:
            screen = .question(max(visibleQuestions.count - 1, 0))
        case .welcome:
            break
        }
    }

    func beginQuestions() {
        screen = visibleQuestions.isEmpty ? .final : .question(0)
    }

    func finish() {
        onComplete()
    }

    /// Lets someone who's partway through the questions bypass the rest —
    /// persists whatever was answered so far as complete, exactly like
    /// finishing normally, so the app doesn't ask again on the next launch.
    /// Recipe generation already falls back to no personalization for any
    /// questions left unanswered. Only shown mid-questions during
    /// first-time onboarding; closing mid-edit already keeps the profile
    /// complete via close().
    func skip() {
        persist(isComplete: true)
        onComplete()
    }

    /// Dismisses without requiring the remaining questions to be answered.
    /// Only meaningful when `isEditing` — answers are already persisted
    /// incrementally as they're changed.
    func close() {
        onComplete()
    }

    // MARK: - Answers

    func toggle(optionID: String, for question: OnboardingQuestion) {
        var answer = answers[question.id] ?? OnboardingAnswer()

        switch question.kind {
        case .singleSelect:
            answer.selectedOptionIDs = [optionID]

        case .multiSelect(let max):
            if let selectedIndex = answer.selectedOptionIDs.firstIndex(of: optionID) {
                answer.selectedOptionIDs.remove(at: selectedIndex)
            } else {
                let tappedIsExclusive = question.allOptions.first { $0.id == optionID }?.isExclusive == true
                if tappedIsExclusive {
                    answer.selectedOptionIDs = [optionID]
                } else {
                    answer.selectedOptionIDs.removeAll { id in
                        question.allOptions.first { $0.id == id }?.isExclusive == true
                    }
                    if let max, answer.selectedOptionIDs.count >= max {
                        return
                    }
                    answer.selectedOptionIDs.append(optionID)
                }
            }

        case .ranking(let count):
            if let rankedIndex = answer.selectedOptionIDs.firstIndex(of: optionID) {
                answer.selectedOptionIDs.remove(at: rankedIndex)
            } else if answer.selectedOptionIDs.count < count {
                answer.selectedOptionIDs.append(optionID)
            }
        }

        answers[question.id] = answer
        // While editing an already-completed profile, keep it marked
        // complete so personalization keeps working mid-edit; first-time
        // onboarding stays incomplete until completeOnboarding() runs.
        persist(isComplete: isEditing)
    }

    func updateOtherText(_ text: String, for question: OnboardingQuestion) {
        var answer = answers[question.id] ?? OnboardingAnswer()
        answer.otherText = text
        answers[question.id] = answer
    }

    func isSelected(_ optionID: String, for question: OnboardingQuestion) -> Bool {
        answers[question.id]?.selectedOptionIDs.contains(optionID) ?? false
    }

    func rank(of optionID: String, for question: OnboardingQuestion) -> Int? {
        guard let index = answers[question.id]?.selectedOptionIDs.firstIndex(of: optionID) else { return nil }
        return index + 1
    }

    func otherText(for question: OnboardingQuestion) -> String {
        answers[question.id]?.otherText ?? ""
    }

    func selectedCount(for question: OnboardingQuestion) -> Int {
        answers[question.id]?.selectedOptionIDs.count ?? 0
    }

    func canContinue(_ question: OnboardingQuestion) -> Bool {
        let selectedCount = selectedCount(for: question)
        let hasOtherText = !otherText(for: question).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        switch question.kind {
        case .singleSelect:
            return selectedCount == 1
        case .multiSelect:
            return selectedCount >= 1 || (question.allowsOtherText && hasOtherText)
        case .ranking(let count):
            return selectedCount == count
        }
    }

    private func persist(isComplete: Bool) {
        store.save(KitchenProfile(answers: answers, isComplete: isComplete, completedAt: isComplete ? Date() : nil))
    }

    private func completeOnboarding() {
        persist(isComplete: true)
        screen = .final
    }
}
