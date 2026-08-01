//
//  AppReviewEligibility.swift
//  Simmr
//

import FirebaseAuth
import Foundation

/// Resolves "User ID" for feedback/analytics — the Firebase uid when
/// signed in, otherwise a locally-generated id minted once and persisted,
/// since sign-in is fully skippable and the rest of the app already works
/// signed out (see LoginView's "Skip for now").
@MainActor
enum FeedbackUserIdentity {
    private static let key = "com.inspiredevstudio.Simmr.localUserID"

    static func current(defaults: UserDefaults = .standard) -> String {
        if let uid = AuthenticationManager.shared.currentUser?.uid {
            return uid
        }
        if let existing = defaults.string(forKey: key) {
            return existing
        }
        let fresh = UUID().uuidString
        defaults.set(fresh, forKey: key)
        return fresh
    }
}

/// Gates Screen 3 of the positive feedback flow (the App Store review ask)
/// per the spec's four conditions. Rating being 4-5 is enforced by the
/// caller only ever checking this from the positive branch — not repeated
/// here.
enum AppReviewEligibility {
    private static let hasRatedKey = "com.inspiredevstudio.Simmr.hasRatedApp"
    private static let lastMaybeLaterKey = "com.inspiredevstudio.Simmr.lastMaybeLaterAt"
    /// The one arbitrary number in this feature — how long "recently
    /// tapped Maybe Later" should suppress the prompt for. Easy to tune.
    private static let maybeLaterCooldownDays = 30

    static var hasRatedApp: Bool {
        get { UserDefaults.standard.bool(forKey: hasRatedKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasRatedKey) }
    }

    static func recordMaybeLater() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastMaybeLaterKey)
    }

    /// "Not the first completed recipe" and "at least 2 completed recipes"
    /// collapse into one check: a completed-count >= 2 already implies
    /// there was an earlier one.
    static func isEligible(
        cookingSessionRepository: CookingSessionRepository = LocalCookingSessionRepository()
    ) async -> Bool {
        guard !hasRatedApp, !recentlyTappedMaybeLater() else { return false }

        let completedCount = (try? await cookingSessionRepository.fetchAllSessions())?
            .filter { $0.status == .completed }
            .count ?? 0
        return completedCount >= 2
    }

    private static func recentlyTappedMaybeLater() -> Bool {
        let lastTimestamp = UserDefaults.standard.double(forKey: lastMaybeLaterKey)
        guard lastTimestamp > 0 else { return false }
        let cooldownSeconds = TimeInterval(maybeLaterCooldownDays * 24 * 60 * 60)
        return Date().timeIntervalSince(Date(timeIntervalSince1970: lastTimestamp)) < cooldownSeconds
    }
}
