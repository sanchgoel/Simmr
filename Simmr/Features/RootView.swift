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
    }

    @ViewBuilder
    private var content: some View {
        if isOnboardingComplete {
            HomeView()
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
