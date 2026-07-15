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

    init(onComplete: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(onComplete: onComplete))
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.showsProgressBar {
                header
            }

            content
        }
        .background(Theme.Colors.creamBackground.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.2), value: viewModel.screen)
    }

    private var header: some View {
        VStack(spacing: Theme.Spacing.sm) {
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
            StepProgressBar(progress: viewModel.progress)
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
