//
//  TasteRatingScreen.swift
//  Simmr
//
//  Screen 1 — the entry point of the feedback flow. Routes to the
//  positive or improvement branch based on the selected rating.
//

import SwiftUI

struct TasteRatingScreen: View {
    @ObservedObject var viewModel: PostCookingFeedbackViewModel

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            CelebrationHeaderView(
                title: "Time for the best part 😋",
                subtitle: "Go ahead, taste it. We'll wait."
            )

            VStack(spacing: Theme.Spacing.md) {
                Text("How did your \(viewModel.recipeTitle) turn out?")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textDark)
                    .multilineTextAlignment(.center)

                StarRatingControl(rating: $viewModel.rating, starSize: 44)
            }

            Spacer()

            Button("Continue", action: viewModel.continueFromRating)
                .buttonStyle(.primary)
                .disabled(viewModel.rating == nil)
                .opacity(viewModel.rating == nil ? 0.5 : 1)
        }
        .padding(Theme.Spacing.lg)
    }
}
