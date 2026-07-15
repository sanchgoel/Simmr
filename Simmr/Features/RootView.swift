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

    init() {
        _isOnboardingComplete = State(initialValue: UserDefaultsKitchenProfileStore().load()?.isComplete ?? false)
    }

    var body: some View {
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
