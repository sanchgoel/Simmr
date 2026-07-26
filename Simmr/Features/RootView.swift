//
//  RootView.swift
//  Simmr
//
//  Gates the app behind onboarding until the user has a completed Kitchen
//  Profile. Once complete, shows Home for the rest of the app's lifetime.
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
        if isOnboardingComplete {
            HomeView(initialPath: restoredState.path)
        } else {
            OnboardingContainerView {
                isOnboardingComplete = true
            }
        }
    }
}

#Preview {
    RootView()
}
