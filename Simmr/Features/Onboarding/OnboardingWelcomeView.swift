//
//  OnboardingWelcomeView.swift
//  Simmr
//

import SwiftUI

struct OnboardingWelcomeView: View {
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Spacer()

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Let's build your Kitchen Profile")
                    .font(Theme.Typography.largeTitle)
                    .foregroundStyle(Theme.Colors.textDark)

                Text("Answer a few quick questions so we can personalize recipes, recommendations and your AI cooking companion. You can update these anytime.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textMuted)
            }

            Spacer()
            Spacer()

            Button("Let's Go") { onStart() }
                .buttonStyle(.primary)
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

#Preview {
    OnboardingWelcomeView {}
        .background(Theme.Colors.creamBackground)
}
