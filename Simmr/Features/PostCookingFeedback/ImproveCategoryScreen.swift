//
//  ImproveCategoryScreen.swift
//  Simmr
//
//  Screen 2, step 1 of the negative/neutral flow — tapping a card
//  immediately pushes to ImproveDetailScreen, no Continue button.
//

import SwiftUI

struct ImproveCategoryScreen: View {
    @ObservedObject var viewModel: PostCookingFeedbackViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                Spacer().frame(height: Theme.Spacing.lg)

                CelebrationHeaderView(
                    title: "Help us improve ❤️",
                    subtitle: "What could we do better next time?"
                )

                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(FeedbackImproveCategory.allCases) { category in
                        LargeOptionCard(title: category.label) {
                            viewModel.selectImproveCategory(category)
                        }
                    }
                }
            }
            .padding(Theme.Spacing.lg)
        }
    }
}
