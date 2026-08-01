//
//  PostCookingFeedbackViewModel.swift
//  Simmr
//
//  Mirrors OnboardingViewModel's enum Screen + @Published pattern — the
//  closest existing precedent for a branching (not strictly linear)
//  multi-step flow. Owns routing, submission, and analytics; the actual
//  timing of `path.removeAll()` back in Home stays owned by
//  CookingModeView's own `.sheet(onDismiss:)`, not duplicated here —
//  `onDismiss` is just called once the flow is done with itself.
//

import Combine
import SwiftUI

@MainActor
final class PostCookingFeedbackViewModel: ObservableObject {
    enum FeedbackScreen: Equatable {
        case rating
        case showItOff
        case appReview
        case improveCategory
        case improveDetail
        case thankYou
    }

    /// Shared push/pop-style spring — every screen transition in this flow
    /// uses this same timing, matching the "consistent spring timing"
    /// requirement rather than each call site picking its own.
    private static let pushAnimation = Animation.spring(response: 0.35, dampingFraction: 0.8)

    @Published var screen: FeedbackScreen = .rating
    @Published var rating: Int?
    @Published var selectedImproveCategory: FeedbackImproveCategory?
    @Published var selectedImproveDetail: String?
    @Published var additionalFeedbackText: String = ""
    @Published var pickedPhoto: UIImage?
    @Published var shareContent: ShareContent?

    let recipeTitle: String
    private let cookingSessionID: UUID
    private let startedAt: Date
    private let userID: String
    private let feedbackRepository: FeedbackRepository
    private let analyticsLogger: FeedbackAnalyticsLogger
    private let onDismiss: () -> Void

    /// Guards against writing two FeedbackRecords for the same cook if
    /// finishFlow()/closeFlow() were somehow both triggered.
    private var didSubmitRecord = false

    init(
        recipeTitle: String,
        cookingSessionID: UUID,
        startedAt: Date,
        feedbackRepository: FeedbackRepository = LocalFeedbackRepository(),
        analyticsLogger: FeedbackAnalyticsLogger = ConsoleFeedbackAnalyticsLogger(),
        onDismiss: @escaping () -> Void
    ) {
        self.recipeTitle = recipeTitle
        self.cookingSessionID = cookingSessionID
        self.startedAt = startedAt
        self.userID = FeedbackUserIdentity.current()
        self.feedbackRepository = feedbackRepository
        self.analyticsLogger = analyticsLogger
        self.onDismiss = onDismiss
        log(.flowShown)
    }

    private var sessionDurationSeconds: Int {
        max(0, Int(Date().timeIntervalSince(startedAt)))
    }

    private var screenName: String {
        switch screen {
        case .rating: "rating"
        case .showItOff: "showItOff"
        case .appReview: "appReview"
        case .improveCategory: "improveCategory"
        case .improveDetail: "improveDetail"
        case .thankYou: "thankYou"
        }
    }

    private func log(_ event: FeedbackAnalyticsEvent) {
        let context = FeedbackAnalyticsContext(
            userID: userID,
            cookingSessionID: cookingSessionID,
            recipeTitle: recipeTitle,
            rating: rating,
            sessionDurationSeconds: sessionDurationSeconds
        )
        analyticsLogger.log(event, context: context)
    }

    // MARK: - Screen 1: Taste & Rate

    func selectRating(_ value: Int) {
        rating = value
        log(.ratingSelected(value))
    }

    /// 4-5 stars -> positive flow, 1-3 stars -> improvement category picker.
    func continueFromRating() {
        guard let rating else { return }
        withAnimation(Self.pushAnimation) {
            screen = rating >= 4 ? .showItOff : .improveCategory
        }
    }

    // MARK: - Positive flow

    func addPhoto(_ image: UIImage) {
        pickedPhoto = image
        log(.photoAdded)
    }

    /// Sharing never requires a photo first — works with just the share text.
    func presentShareSheet() {
        log(.shareClicked)
        let text = "I just made \(recipeTitle) with Simmr—and it turned out pretty great! 👨‍🍳"
        shareContent = ShareContent(text: text, image: pickedPhoto)
    }

    func shareSheetDismissed(completed: Bool) {
        shareContent = nil
        if completed {
            log(.shareCompleted)
        }
    }

    /// The single forward action on this screen (spec's "Skip") — moves on
    /// regardless of whether a photo/share happened first, into the
    /// eligibility-gated App Store ask or straight to a close.
    func advanceFromShowItOff() {
        Task {
            let eligible = await AppReviewEligibility.isEligible()
            if eligible {
                log(.ratingPromptShown)
            }
            withAnimation(Self.pushAnimation) {
                if eligible {
                    screen = .appReview
                } else {
                    finishFlow()
                }
            }
        }
    }

    func rateSimmrTapped() {
        AppReviewEligibility.hasRatedApp = true
        log(.ratingCTAClicked)
        finishFlow()
    }

    func maybeLaterTapped() {
        AppReviewEligibility.recordMaybeLater()
        log(.maybeLaterTapped)
        finishFlow()
    }

    // MARK: - Negative flow — two-step drill-down, no typing anywhere

    /// Tapping a category immediately advances — no Continue button, per
    /// spec ("do not require a Continue button").
    func selectImproveCategory(_ category: FeedbackImproveCategory) {
        selectedImproveCategory = category
        log(.improveCategorySelected(category))
        withAnimation(Self.pushAnimation) {
            screen = .improveDetail
        }
    }

    /// Tapping a reason just marks the selection — Submit Feedback below is
    /// the actual forward action, since there's now an optional note field
    /// on this screen too.
    func selectImproveDetail(_ detail: String) {
        selectedImproveDetail = detail
    }

    /// The one forward action on the detail screen — persists the rating +
    /// selection + optional note and shows Thank You. Persisting here
    /// rather than waiting for Done means the record is saved even if the
    /// user swipes away from Thank You instead of tapping it.
    func submitImproveFeedback() {
        guard selectedImproveDetail != nil else { return }
        log(.feedbackSubmitted)
        hasFinished = true
        persistRecord(completed: true)
        withAnimation(Self.pushAnimation) {
            screen = .thankYou
        }
    }

    func done() {
        finishFlow()
    }

    // MARK: - Dismissal (always allowed, from any screen)

    /// True once the flow has logged/persisted its own end, via either
    /// closeFlow(), finishFlow(), or a swipe-to-dismiss caught by
    /// handleDisappearIfNeeded() — guards against double-logging when more
    /// than one of those paths fires for the same dismissal.
    private var hasFinished = false

    func closeFlow() {
        recordDismissal()
        onDismiss()
    }

    /// Catches swipe-to-dismiss, which never calls closeFlow() — SwiftUI's
    /// .sheet still flips its own isPresented binding and fires
    /// CookingModeView's onDismiss (path.removeAll()) in that case, but
    /// nothing else would log/persist the early exit without this.
    func handleDisappearIfNeeded() {
        guard !hasFinished else { return }
        recordDismissal()
    }

    private func recordDismissal() {
        guard !hasFinished else { return }
        hasFinished = true
        log(.flowDismissed(screen: screenName))
        if rating != nil {
            persistRecord(completed: false)
        }
    }

    private func finishFlow() {
        hasFinished = true
        log(.flowCompleted)
        persistRecord(completed: true)
        onDismiss()
    }

    /// No record is written if the flow was closed before a rating was
    /// ever selected — FeedbackRecord.rating is non-optional, and there's
    /// nothing meaningful to persist yet at that point (the dismissal
    /// itself is still captured via the .flowDismissed analytics event).
    private func persistRecord(completed: Bool) {
        guard let rating, !didSubmitRecord else { return }
        didSubmitRecord = true
        let trimmedNote = additionalFeedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
        let record = FeedbackRecord(
            id: UUID(),
            cookingSessionID: cookingSessionID,
            recipeTitle: recipeTitle,
            userID: userID,
            rating: rating,
            improveCategory: selectedImproveCategory,
            improveDetail: selectedImproveDetail,
            improveNote: trimmedNote.isEmpty ? nil : trimmedNote,
            photoIncluded: pickedPhoto != nil,
            sessionDurationSeconds: sessionDurationSeconds,
            flowCompleted: completed,
            dismissedAtScreen: completed ? nil : screenName,
            createdAt: Date()
        )
        let repository = feedbackRepository
        Task {
            try? await repository.save(record)
        }
    }
}
