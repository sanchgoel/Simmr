//
//  OnboardingFinalView.swift
//  Simmr
//

import SwiftUI

struct OnboardingFinalView: View {
    let onFinish: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Spacer()

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("🎉")
                    .font(.system(size: 48))

                Text("Your Kitchen Profile is ready!")
                    .font(Theme.Typography.largeTitle)
                    .foregroundStyle(Theme.Colors.textDark)

                Text("We'll personalize recipes, cooking guidance and recommendations based on your preferences. You can update these anytime from Settings.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textMuted)
            }

            Spacer()
            Spacer()

            Button("Start Cooking") { onFinish() }
                .buttonStyle(.primary)
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

#Preview {
    OnboardingFinalView {}
        .background(Theme.Colors.creamBackground)
}
