//
//  CookingModeView.swift
//  Simmr
//

import SwiftUI
import UIKit

struct CookingModeView: View {
    @StateObject private var viewModel: CookingModeViewModel
    @Binding var path: [AppRoute]
    @Environment(\.scenePhase) private var scenePhase
    @State private var converterPreset: ConverterPreset?
    @State private var isShowingFeedbackFlow = false

    init(session: RecipeSession, path: Binding<[AppRoute]>, existingCookingSession: CookingSession? = nil) {
        _viewModel = StateObject(wrappedValue: CookingModeViewModel(
            recipe: session.recipe,
            ingredients: session.ingredients,
            servings: session.servings,
            existingCookingSession: existingCookingSession
        ))
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
                .padding(.horizontal, Theme.Spacing.lg)
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
                        TimerControl(
                            remaining: viewModel.timerRemaining,
                            progress: viewModel.timerProgress,
                            isRunning: viewModel.isTimerRunning,
                            isComplete: viewModel.isTimerComplete,
                            canDecreaseMinute: viewModel.canDecreaseTimerMinute,
                            onStart: viewModel.startTimer,
                            onPause: viewModel.pauseTimer,
                            onReset: viewModel.resetTimer,
                            onIncrementMinute: viewModel.incrementTimerMinute,
                            onDecrementMinute: viewModel.decrementTimerMinute,
                            onContinue: advanceOrFinish
                        )
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    converterPreset = ConverterPreset(options: convertibleOptions, selectedOptionID: convertibleOptions.first?.id)
                } label: {
                    Image(systemName: "arrow.triangle.swap")
                        .foregroundStyle(Theme.Colors.textDark)
                }
            }
        }
        .sheet(item: $converterPreset) { preset in
            UnitConverterView(options: preset.options, selectedOptionID: preset.selectedOptionID)
        }
        .onAppear {
            // Covers resuming a session whose timer was already running
            // (restored from a persisted CookingSession) — onChange below
            // only fires on a subsequent start/pause, not on initial state.
            UIApplication.shared.isIdleTimerDisabled = viewModel.isTimerRunning
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.refreshTimerIfNeeded()
            }
        }
        .onChange(of: viewModel.didFinishExternally) { _, finishedExternally in
            if finishedExternally {
                isShowingFeedbackFlow = true
            }
        }
        .onChange(of: viewModel.isTimerRunning) { _, isRunning in
            // Keeps the screen awake while a timer is actively counting down,
            // so glancing at it doesn't require touching the phone every
            // 30 seconds. Only meaningful while this view is frontmost — the
            // Live Activity is what keeps the countdown alive once the phone
            // does lock or the app backgrounds.
            UIApplication.shared.isIdleTimerDisabled = isRunning
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            viewModel.endCookingSession()
        }
        .sheet(isPresented: $isShowingFeedbackFlow, onDismiss: { path.removeAll() }) {
            PostCookingFeedbackFlowView(
                recipeTitle: viewModel.recipe.title,
                cookingSessionID: viewModel.sessionID,
                startedAt: viewModel.startedAt,
                onDismiss: { isShowingFeedbackFlow = false }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Theme.Colors.creamBackground)
            .interactiveDismissDisabled(false)
        }
    }

    private var ingredientsUsedRow: some View {
        FlowLayout(spacing: Theme.Spacing.xs) {
            ForEach(viewModel.currentStepIngredients) { ingredient in
                ingredientChip(ingredient)
            }
        }
    }

    @ViewBuilder
    private func ingredientChip(_ ingredient: CookingModeViewModel.UsedIngredient) -> some View {
        if let option = convertibleOptions.first(where: { $0.name == ingredient.name }) {
            Button {
                converterPreset = ConverterPreset(options: convertibleOptions, selectedOptionID: option.id)
            } label: {
                ingredientChipLabel(ingredient, isConvertible: true)
            }
            .buttonStyle(.plain)
        } else {
            ingredientChipLabel(ingredient, isConvertible: false)
        }
    }

    private func ingredientChipLabel(_ ingredient: CookingModeViewModel.UsedIngredient, isConvertible: Bool) -> some View {
        HStack(spacing: 5) {
            Text(ingredient.name)
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Colors.textDark)
            if let quantityLabel = ingredient.quantityLabel {
                Text(quantityLabel)
                    .font(Theme.Typography.footnote.weight(.semibold))
                    .foregroundStyle(Theme.Colors.coral)
            }
            if isConvertible {
                Image(systemName: "arrow.triangle.swap")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Theme.Colors.coral.opacity(0.7))
            }
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(Theme.Colors.tint)
        .clipShape(Capsule())
    }

    /// All of the current step's ingredients that have a recognized
    /// weight/volume unit, in order — feeds both the toolbar converter
    /// (defaults to the first) and each chip's tap target.
    private var convertibleOptions: [ConvertibleIngredientOption] {
        viewModel.currentStepIngredients.compactMap { ingredient in
            guard let quantity = ingredient.quantity, let unitText = ingredient.unit else { return nil }
            if let volumeUnit = VolumeUnit(matching: unitText) {
                return ConvertibleIngredientOption(name: ingredient.name, category: .volume, quantity: quantity, volumeUnit: volumeUnit, weightUnit: nil)
            }
            if let weightUnit = WeightUnit(matching: unitText) {
                return ConvertibleIngredientOption(name: ingredient.name, category: .weight, quantity: quantity, volumeUnit: nil, weightUnit: weightUnit)
            }
            return nil
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

            Button(viewModel.isLastStep ? "Finish" : "Next", action: advanceOrFinish)
                .buttonStyle(.primary)
        }
    }

    /// Advances to the next step, or finishes the recipe on the last step —
    /// shared by the bottom nav buttons and the timer's own "Continue
    /// Cooking" completion button so both paths stay identical.
    private func advanceOrFinish() {
        if viewModel.isLastStep {
            viewModel.finishCooking()
            isShowingFeedbackFlow = true
        } else {
            viewModel.goToNextStep()
        }
    }
}

/// A step ingredient with a recognized weight/volume unit, offered as a
/// choice in the unit converter's ingredient picker.
///
/// `id` is derived from `name` rather than a fresh UUID, because
/// `convertibleOptions` below is a computed property re-evaluated on every
/// access — a random UUID would mint a new identity each time, so an ID
/// captured from one access (e.g. a tapped chip) would never match the
/// array passed into `ConverterPreset` moments later, and the sheet would
/// silently fall back to the first ingredient instead of the tapped one.
struct ConvertibleIngredientOption: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let category: ConversionCategory
    let quantity: Double
    let volumeUnit: VolumeUnit?
    let weightUnit: WeightUnit?
}

/// Seeds the unit converter sheet with the current step's convertible
/// ingredients (possibly empty) and which one to preselect.
struct ConverterPreset: Identifiable {
    let id = UUID()
    var options: [ConvertibleIngredientOption]
    var selectedOptionID: ConvertibleIngredientOption.ID?
}

#Preview {
    NavigationStack {
        CookingModeView(session: RecipeSession(recipe: .preview), path: .constant([]))
    }
}
