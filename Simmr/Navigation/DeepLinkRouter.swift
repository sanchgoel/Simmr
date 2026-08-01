//
//  DeepLinkRouter.swift
//  Simmr
//
//  Parses `simmr://` URLs (see SimmrApp.onOpenURL) and exposes the result as
//  published state RootView observes. Today the only deep link is the
//  finished Live Activity's "Rate it" button, which needs to open the
//  post-cooking feedback flow for a specific session even when the app was
//  fully killed at the moment cooking finished — see
//  LiveActivityManager.showFinishedPrompt() and CookingSessionManager.
//

import Combine
import Foundation

@MainActor
final class DeepLinkRouter: ObservableObject {
    static let shared = DeepLinkRouter()

    @Published var pendingFeedbackSessionID: UUID?

    private init() {}

    /// Returns true if this app recognized and handled the URL — false
    /// means it wasn't ours (e.g. GoogleSignIn's redirect), so the caller
    /// should try another handler.
    func handle(_ url: URL) -> Bool {
        guard url.scheme == "simmr" else { return false }
        guard url.host == "feedback",
              let sessionIDString = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                  .queryItems?.first(where: { $0.name == "sessionID" })?.value,
              let sessionID = UUID(uuidString: sessionIDString)
        else { return true }

        pendingFeedbackSessionID = sessionID
        return true
    }
}
