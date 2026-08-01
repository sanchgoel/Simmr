//
//  RootView.swift
//  Simmr
//
//  Gates the app behind onboarding until the user has a completed Kitchen
//  Profile. Once complete, shows the app's main tab navigation.
//

import SwiftUI

struct RootView: View {
    @State private var isOnboardingComplete: Bool
    @State private var isLaunchAnimationComplete = false
    /// Whether an in-progress cook should be restored straight into Cooking
    /// Mode instead of Home. Resolved by a `.task` below that runs
    /// concurrently with the launch animation, so it's ready well before
    /// `content` ever appears — LaunchAnimationView's ~1.4s fixed sequence
    /// comfortably outlasts a local UserDefaults read.
    @State private var restoredState = RestoredLaunchState.none
    @State private var isShowingDebugLog = false
    @State private var deepLinkFeedbackContext: DeepLinkFeedbackContext?
    @ObservedObject private var authManager = AuthenticationManager.shared
    @ObservedObject private var deepLinkRouter = DeepLinkRouter.shared
    /// Separate from `isOnboardingComplete` so already-onboarded installs
    /// (from before sign-in existed) are prompted exactly once too, not
    /// just fresh ones — set the moment LoginView is skipped or a sign-in
    /// succeeds, never reset afterward.
    @AppStorage("com.inspiredevstudio.simmr.hasSeenLoginPrompt") private var hasSeenLoginPrompt = false

    init() {
        _isOnboardingComplete = State(initialValue: UserDefaultsKitchenProfileStore().load()?.isComplete ?? false)
    }

    var body: some View {
        ZStack {
            if isLaunchAnimationComplete {
                content
                    .transition(.opacity)
            } else {
                LaunchAnimationView {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isLaunchAnimationComplete = true
                    }
                }
                .transition(.opacity)
            }
        }
        .task {
            // A signed-in account (Firebase Auth restores its session from
            // the Keychain on its own, independent of local storage) with
            // nothing in local storage — a fresh install, or a reinstall —
            // otherwise looks like starting over even though everything is
            // sitting in Firestore. Runs before the onboarding/Home decision
            // below, so a restored Kitchen Profile is picked up immediately.
            if authManager.currentUser != nil {
                await FirestoreSyncManager.shared.restoreFromFirestoreIfNeeded()
                isOnboardingComplete = UserDefaultsKitchenProfileStore().load()?.isComplete ?? false
            }
            guard isOnboardingComplete else { return }
            restoredState = await CookingSessionRestorer.restore()
        }
        .onShake {
            guard BuildEnvironment.isDebugToolsEnabled else { return }
            isShowingDebugLog = true
        }
        .sheet(isPresented: $isShowingDebugLog) {
            APIDebugLogView()
        }
        .onChange(of: deepLinkRouter.pendingFeedbackSessionID) { _, sessionID in
            guard let sessionID else { return }
            deepLinkRouter.pendingFeedbackSessionID = nil
            Task { await presentFeedbackFlow(forSessionID: sessionID) }
        }
        .fullScreenCover(item: $deepLinkFeedbackContext) { context in
            PostCookingFeedbackFlowView(
                recipeTitle: context.recipeTitle,
                cookingSessionID: context.cookingSessionID,
                startedAt: context.startedAt,
                onDismiss: {
                    deepLinkFeedbackContext = nil
                    LiveActivityManager.shared.end()
                }
            )
        }
    }

    /// Opened by the finished Live Activity's "Rate it" deep link — may run
    /// with no CookingModeViewModel alive (the app could've been fully
    /// killed when cooking finished), so this looks the session up fresh
    /// from local storage rather than relying on any in-memory state.
    private func presentFeedbackFlow(forSessionID sessionID: UUID) async {
        let repository = LocalCookingSessionRepository()
        guard var session = try? await repository.fetchAllSessions().first(where: { $0.id == sessionID }) else { return }

        if session.status != .completed {
            session.status = .completed
            session.updatedAt = Date()
            try? await repository.save(session)
        }

        deepLinkFeedbackContext = DeepLinkFeedbackContext(
            recipeTitle: session.recipe.title,
            cookingSessionID: session.id,
            startedAt: session.startedAt
        )
    }

    @ViewBuilder
    private var content: some View {
        if !isOnboardingComplete {
            OnboardingContainerView {
                isOnboardingComplete = true
            }
        } else if authManager.currentUser == nil && !hasSeenLoginPrompt {
            LoginView {
                hasSeenLoginPrompt = true
            }
        } else {
            MainTabView(initialHomePath: restoredState.path)
        }
    }
}

/// Feeds `PostCookingFeedbackFlowView`'s init from a deep-link-resolved
/// CookingSession — `id` is the session's own id so `.fullScreenCover(item:)`
/// can key off it directly.
private struct DeepLinkFeedbackContext: Identifiable {
    let recipeTitle: String
    let cookingSessionID: UUID
    let startedAt: Date
    var id: UUID { cookingSessionID }
}

#Preview {
    RootView()
}
