//
//  ImproveDetailScreen.swift
//  Simmr
//
//  Screen 2, step 2 of the negative/neutral flow — pick a specific reason
//  (single-select, no chevron since it doesn't drill further), optionally
//  add a note, then Submit Feedback persists everything and shows Thank You.
//

import SwiftUI

struct ImproveDetailScreen: View {
    @ObservedObject var viewModel: PostCookingFeedbackViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                Spacer().frame(height: Theme.Spacing.lg)

                if let category = viewModel.selectedImproveCategory {
                    CelebrationHeaderView(title: category.detailTitle)

                    VStack(spacing: Theme.Spacing.sm) {
                        ForEach(category.detailOptions, id: \.self) { option in
                            SelectableOptionCard(
                                title: option,
                                isSelected: viewModel.selectedImproveDetail == option
                            ) {
                                viewModel.selectImproveDetail(option)
                            }
                        }
                    }

                    FeedbackTextField(
                        text: $viewModel.additionalFeedbackText,
                        placeholder: "Anything else you'd like to explain? (optional)",
                        helperText: "Totally optional — your selection above already helps a lot."
                    )

                    Button("Submit Feedback", action: viewModel.submitImproveFeedback)
                        .buttonStyle(.primary)
                        .disabled(viewModel.selectedImproveDetail == nil)
                        .opacity(viewModel.selectedImproveDetail == nil ? 0.5 : 1)
                }
            }
            .padding(Theme.Spacing.lg)
        }
    }
}
