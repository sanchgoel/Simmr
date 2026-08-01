//
//  AppStoreReviewPromptView.swift
//  Simmr
//
//  Reusable "ask for a rating" card — standalone so it can be reused
//  outside the feedback flow later (e.g. a Settings "Rate Us" row), not
//  just wrapped by RateSimmrScreen. No SKStoreReviewController/StoreKit
//  review precedent exists anywhere else in the app; this is the first.
//

import StoreKit
import SwiftUI
import UIKit

/// Placeholder until Simmr has a real App Store listing — only used as the
/// fallback when AppStore.requestReview(in:) has no foreground window
/// scene to work with.
enum AppStoreConfiguration {
    /// TODO: replace with the real numeric App Store Connect app ID once Simmr is listed.
    static let appStoreID = "0000000000"

    static var reviewURL: URL? {
        URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")
    }
}

struct AppStoreReviewPromptView: View {
    var title: String = "Tiny favour? ❤️"
    var message: String = "If Simmr helped you cook something you're proud of today, would you mind leaving us a quick rating?"
    var onRate: () -> Void
    var onMaybeLater: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            CelebrationHeaderView(title: title, subtitle: message)

            VStack(spacing: Theme.Spacing.sm) {
                Button("⭐ Rate Simmr", action: requestReview)
                    .buttonStyle(.primary)

                Button("Maybe Later", action: onMaybeLater)
                    .buttonStyle(.secondary)
            }
        }
    }

    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            AppStore.requestReview(in: scene)
        } else if let url = AppStoreConfiguration.reviewURL {
            UIApplication.shared.open(url)
        }
        onRate()
    }
}

#Preview {
    AppStoreReviewPromptView(onRate: {}, onMaybeLater: {})
        .padding()
        .background(Theme.Colors.creamBackground)
}
