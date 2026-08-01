//
//  FeedbackAnalyticsEvent.swift
//  Simmr
//
//  Every interaction event the post-cooking feedback flow needs to
//  capture. Kept separate from FeedbackRecord (the persisted, meaningful
//  feedback submission) since these are ephemeral funnel/interaction
//  events, not something that needs to survive an app relaunch.
//

import Foundation

enum FeedbackAnalyticsEvent {
    case flowShown
    case ratingSelected(Int)
    case photoAdded
    case shareClicked
    case shareCompleted
    case ratingPromptShown
    case ratingCTAClicked
    case maybeLaterTapped
    case improveCategorySelected(FeedbackImproveCategory)
    case feedbackSubmitted
    case flowCompleted
    case flowDismissed(screen: String)

    /// Stable name for logging/eventual backend export.
    var name: String {
        switch self {
        case .flowShown: "feedback_flow_shown"
        case .ratingSelected: "feedback_rating_selected"
        case .photoAdded: "feedback_photo_added"
        case .shareClicked: "feedback_share_clicked"
        case .shareCompleted: "feedback_share_completed"
        case .ratingPromptShown: "feedback_rating_prompt_shown"
        case .ratingCTAClicked: "feedback_rating_cta_clicked"
        case .maybeLaterTapped: "feedback_maybe_later_tapped"
        case .improveCategorySelected: "feedback_improve_category_selected"
        case .feedbackSubmitted: "feedback_submitted"
        case .flowCompleted: "feedback_flow_completed"
        case .flowDismissed: "feedback_flow_dismissed"
        }
    }
}

/// Shared context attached to every event so call sites don't have to
/// re-pass the same identifiers each time.
struct FeedbackAnalyticsContext {
    let userID: String
    let cookingSessionID: UUID
    let recipeTitle: String
    let rating: Int?
    let sessionDurationSeconds: Int
    let timestamp: Date

    init(
        userID: String,
        cookingSessionID: UUID,
        recipeTitle: String,
        rating: Int? = nil,
        sessionDurationSeconds: Int,
        timestamp: Date = Date()
    ) {
        self.userID = userID
        self.cookingSessionID = cookingSessionID
        self.recipeTitle = recipeTitle
        self.rating = rating
        self.sessionDurationSeconds = sessionDurationSeconds
        self.timestamp = timestamp
    }
}
