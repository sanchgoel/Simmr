//
//  PostCookingFeedbackFlowView.swift
//  Simmr
//
//  Container for the whole post-cooking feedback flow, presented as a
//  bottom sheet immediately after "Finish Cooking" (see CookingModeView).
//  Owns the Close button (always available, per spec) and the screen
//  transition; each screen itself is a plain, mostly-stateless view driven
//  by PostCookingFeedbackViewModel.
//

import SwiftUI

struct PostCookingFeedbackFlowView: View {
    @StateObject private var viewModel: PostCookingFeedbackViewModel

    init(
        recipeTitle: String,
        cookingSessionID: UUID,
        startedAt: Date,
        onDismiss: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: PostCookingFeedbackViewModel(
            recipeTitle: recipeTitle,
            cookingSessionID: cookingSessionID,
            startedAt: startedAt,
            onDismiss: onDismiss
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: viewModel.closeFlow) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textDark)
                        .frame(width: 32, height: 32)
                        .background(Theme.Colors.creamCard)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.sm)

            content
                .id(viewModel.screen)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                .frame(maxHeight: .infinity)
        }
        .background(Theme.Colors.creamBackground.ignoresSafeArea())
        .sheet(item: $viewModel.shareContent) { content in
            ActivityShareSheet(items: content.activityItems) { completed in
                viewModel.shareSheetDismissed(completed: completed)
            }
        }
        .onDisappear {
            // Catches swipe-to-dismiss, which never calls closeFlow() —
            // CookingModeView's own .sheet(onDismiss:) already handles
            // path.removeAll() regardless of cause; this just makes sure
            // the analytics/incomplete-record side of an early exit still
            // gets recorded.
            viewModel.handleDisappearIfNeeded()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.screen {
        case .rating:
            TasteRatingScreen(viewModel: viewModel)
        case .showItOff:
            ShowItOffScreen(viewModel: viewModel)
        case .appReview:
            RateSimmrScreen(viewModel: viewModel)
        case .improveCategory:
            ImproveCategoryScreen(viewModel: viewModel)
        case .improveDetail:
            ImproveDetailScreen(viewModel: viewModel)
        case .thankYou:
            ThankYouScreen(viewModel: viewModel)
        }
    }
}

#Preview {
    PostCookingFeedbackFlowView(
        recipeTitle: "Butter Chicken",
        cookingSessionID: UUID(),
        startedAt: Date().addingTimeInterval(-1200),
        onDismiss: {}
    )
}
