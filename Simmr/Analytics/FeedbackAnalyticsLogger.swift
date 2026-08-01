//
//  FeedbackAnalyticsLogger.swift
//  Simmr
//
//  No analytics infrastructure exists anywhere else in the app yet (no
//  Firebase Analytics import, no custom event pipeline) — this is a
//  minimal protocol-based seam so a real backend can be wired in behind
//  ConsoleFeedbackAnalyticsLogger later without touching any call site.
//

import Foundation

protocol FeedbackAnalyticsLogger {
    func log(_ event: FeedbackAnalyticsEvent, context: FeedbackAnalyticsContext)
}

struct ConsoleFeedbackAnalyticsLogger: FeedbackAnalyticsLogger {
    func log(_ event: FeedbackAnalyticsEvent, context: FeedbackAnalyticsContext) {
        var pieces = ["[Feedback Analytics] \(event.name)", "user=\(context.userID)", "session=\(context.cookingSessionID)", "recipe=\(context.recipeTitle)"]
        if let rating = context.rating {
            pieces.append("rating=\(rating)")
        }
        pieces.append("duration=\(context.sessionDurationSeconds)s")
        if case .ratingSelected(let value) = event {
            pieces.append("selected=\(value)")
        }
        if case .improveCategorySelected(let category) = event {
            pieces.append("category=\(category.rawValue)")
        }
        if case .flowDismissed(let screen) = event {
            pieces.append("screen=\(screen)")
        }
        print(pieces.joined(separator: " "))
    }
}
