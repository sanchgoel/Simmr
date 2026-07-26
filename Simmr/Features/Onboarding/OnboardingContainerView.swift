//
//  OnboardingContainerView.swift
//  Simmr
//
//  Owns the persistent progress bar / back button chrome and swaps the
//  Welcome / Question / Final content beneath it based on flow state.
//

import SwiftUI

struct OnboardingContainerView: View {
    @StateObject private var viewModel: OnboardingViewModel

    /// `isEditing: true` (from Settings > Edit Kitchen Profile) skips the
    /// welcome screen and shows a close button, since the user has already
    /// completed onboarding once. `false` is first-time onboarding.
    init(isEditing: Bool = false, onComplete: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(isEditing: isEditing, onComplete: onComplete))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .background(Theme.Colors.creamBackground.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.2), value: viewModel.screen)
    }

    private var header: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ZStack {
                Text("Simmr")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textDark)

                if viewModel.showsProgressBar {
                    HStack {
                        Button(action: viewModel.goBack) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Theme.Colors.textDark)
                                .frame(width: 32, height: 32)
                                .background(Theme.Colors.creamCard)
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                }

                if viewModel.isEditing {
                    HStack {
                        Spacer()
                        Button(action: viewModel.close) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Theme.Colors.textDark)
                                .frame(width: 32, height: 32)
                                .background(Theme.Colors.creamCard)
                                .clipShape(Circle())
                        }
                    }
                } else if viewModel.showsProgressBar {
                    // Only once someone's actually mid-questions — not on
                    // the welcome screen (nothing to skip past yet) or the
                    // final screen (already done).
                    HStack {
                        Spacer()
                        Button("Skip", action: viewModel.skip)
                            .font(Theme.Typography.footnote.weight(.semibold))
                            .foregroundStyle(Theme.Colors.textMuted)
                    }
                }
            }

            if viewModel.showsProgressBar {
                StepProgressBar(progress: viewModel.progress)
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.sm)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.screen {
        case .welcome:
            OnboardingWelcomeView(onStart: viewModel.beginQuestions)

        case .question(let index):
            if viewModel.visibleQuestions.indices.contains(index) {
                let question = viewModel.visibleQuestions[index]
                OnboardingQuestionView(question: question, viewModel: viewModel)
                    .id(question.id)
            }

        case .final:
            OnboardingFinalView(onFinish: viewModel.finish)
        }
    }
}

#Preview {
    OnboardingContainerView {}
}
