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
    @ObservedObject private var authManager = AuthenticationManager.shared
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

#Preview {
    RootView()
}
