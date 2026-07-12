//
//  CookingModeView.swift
//  Simmr
//

import SwiftUI

struct CookingModeView: View {
    @StateObject private var viewModel: CookingModeViewModel
    @Binding var path: [AppRoute]

    init(session: RecipeSession, path: Binding<[AppRoute]>) {
        _viewModel = StateObject(wrappedValue: CookingModeViewModel(steps: session.steps, ingredients: session.ingredients))
        _path = path
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            VStack(spacing: Theme.Spacing.xs) {
                StepProgressBar(progress: viewModel.progress)
                HStack {
                    Text("Step \(viewModel.stepNumber) of \(viewModel.totalSteps)")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textMuted)
                    Spacer()
                }
            }
            .padding(.top, Theme.Spacing.sm)

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text(viewModel.currentStep.title)
                            .font(Theme.Typography.cookingStepTitle)
                            .foregroundStyle(Theme.Colors.textDark)

                        Text(viewModel.currentStep.instruction)
                            .font(Theme.Typography.cookingInstruction)
                            .foregroundStyle(Theme.Colors.textDark.opacity(0.85))

                        if !viewModel.currentStepIngredients.isEmpty {
                            ingredientsUsedRow
                        }

                        if let tips = viewModel.currentStep.tips {
                            tipsCallout(tips)
                        }
                    }

                    if viewModel.currentStep.hasTimer {
                        HStack {
                            Spacer()
                            TimerControl(
                                remaining: viewModel.timerRemaining,
                                progress: viewModel.timerProgress,
                                isRunning: viewModel.isTimerRunning,
                                isComplete: viewModel.isTimerComplete,
                                onStart: viewModel.startTimer,
                                onPause: viewModel.pauseTimer,
                                onReset: viewModel.resetTimer
                            )
                            Spacer()
                        }
                        .padding(.top, Theme.Spacing.sm)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Theme.Spacing.lg)
                .id(viewModel.stepNumber)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.stepNumber)

            navigationButtons
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.md)
        }
        .background(Theme.Colors.creamBackground.ignoresSafeArea())
        .navigationTitle("Cooking")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
    }

    private var ingredientsUsedRow: some View {
        FlowLayout(spacing: Theme.Spacing.xs) {
            ForEach(viewModel.currentStepIngredients) { ingredient in
                HStack(spacing: 5) {
                    Text(ingredient.name)
                        .font(Theme.Typography.footnote)
                        .foregroundStyle(Theme.Colors.textDark)
                    if let quantityLabel = ingredient.quantityLabel {
                        Text(quantityLabel)
                            .font(Theme.Typography.footnote.weight(.semibold))
                            .foregroundStyle(Theme.Colors.coral)
                    }
                }
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
                .background(Theme.Colors.tint)
                .clipShape(Capsule())
            }
        }
    }

    private func tipsCallout(_ tips: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.xs) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(Theme.Colors.amber)
            Text(tips)
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Colors.textMuted)
        }
        .padding(Theme.Spacing.sm)
        .background(Theme.Colors.creamCard)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
    }

    private var navigationButtons: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Button("Previous") {
                viewModel.goToPreviousStep()
            }
            .buttonStyle(.secondary)
            .disabled(viewModel.isFirstStep)
            .opacity(viewModel.isFirstStep ? 0.5 : 1)

            Button(viewModel.isLastStep ? "Finish" : "Next") {
                if viewModel.isLastStep {
                    path.removeAll()
                } else {
                    viewModel.goToNextStep()
                }
            }
            .buttonStyle(.primary)
        }
    }
}

#Preview {
    NavigationStack {
        CookingModeView(session: RecipeSession(recipe: .preview), path: .constant([]))
    }
}
