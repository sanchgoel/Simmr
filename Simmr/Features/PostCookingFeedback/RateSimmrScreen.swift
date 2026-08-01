//
//  RateSimmrScreen.swift
//  Simmr
//
//  Screen 3 of the positive flow — only ever reached once
//  AppReviewEligibility.isEligible() has already said yes (checked by the
//  view model before routing here), so this just presents the reusable
//  prompt with no further gating of its own.
//

import SwiftUI

struct RateSimmrScreen: View {
    @ObservedObject var viewModel: PostCookingFeedbackViewModel

    var body: some View {
        VStack {
            Spacer()
            AppStoreReviewPromptView(
                onRate: viewModel.rateSimmrTapped,
                onMaybeLater: viewModel.maybeLaterTapped
            )
            Spacer()
        }
        .padding(Theme.Spacing.lg)
    }
}
