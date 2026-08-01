//
//  FeedbackRecord.swift
//  Simmr
//
//  A persisted post-cooking feedback submission. Same shape conventions as
//  CookingSession — plain Optionals, synthesized Codable, no custom
//  CodingKeys — so new fields can be added later without breaking older
//  persisted records, and so this round-trips through Firestore's
//  setData(from:)/data(as:) unchanged whenever a FirebaseFeedbackRepository
//  is introduced.
//

import Foundation

struct FeedbackRecord: Codable, Identifiable, Hashable {
    let id: UUID
    /// Ties this feedback to the CookingSession it was collected for —
    /// Recipe.id is minted fresh on every decode and can't be used for
    /// this, same reasoning as CookingSession's own id.
    let cookingSessionID: UUID
    let recipeTitle: String
    /// Firebase uid when signed in, otherwise the locally-generated
    /// anonymous id from AppReviewEligibility/localUserID — always present.
    let userID: String
    let rating: Int
    /// The negative/neutral flow's two-step drill-down selection — nil for
    /// the positive flow, where these screens never appear.
    let improveCategory: FeedbackImproveCategory?
    let improveDetail: String?
    /// Optional free-text elaboration on the detail screen — always
    /// optional, never required to submit.
    let improveNote: String?
    /// The picked photo itself is never persisted (no photo-storage
    /// convention exists in this app yet) — just whether one was attached.
    let photoIncluded: Bool
    let sessionDurationSeconds: Int
    let flowCompleted: Bool
    /// Non-nil only when the flow was dismissed early (Close button or
    /// swipe-to-dismiss) rather than reaching its natural final screen.
    let dismissedAtScreen: String?
    let createdAt: Date
}
