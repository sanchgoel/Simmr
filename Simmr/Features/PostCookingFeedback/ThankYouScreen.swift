//
//  ThankYouScreen.swift
//  Simmr
//
//  Screen 3 of the negative/neutral flow — deliberately no Share, Photo,
//  or App Store prompt here, per spec.
//

import SwiftUI

struct ThankYouScreen: View {
    @ObservedObject var viewModel: PostCookingFeedbackViewModel

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            CelebrationHeaderView(
                title: "Thanks for helping us improve 🙌",
                subtitle: "We'll use your feedback to make this recipe better for your next cook—and for everyone else."
            )

            Spacer()

            Button("Done", action: viewModel.done)
                .buttonStyle(.primary)
        }
        .padding(Theme.Spacing.lg)
    }
}
