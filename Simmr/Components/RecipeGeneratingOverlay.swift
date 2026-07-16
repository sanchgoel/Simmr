//
//  RecipeGeneratingOverlay.swift
//  Simmr
//
//  Full-screen loader shown while a pasted recipe is being parsed, with a
//  simmering-pot animation and a cycling status message.
//

import SwiftUI

struct RecipeGeneratingOverlay: View {
    private static let messages = [
        "Analysing your recipe…",
        "Breaking down the steps…",
        "Estimating quantities…",
        "Optimising the cooking order…",
        "Personalising to your taste…",
        "Almost ready…",
    ]

    @State private var messageIndex = 0

    var body: some View {
        ZStack {
            Theme.Colors.creamBackground.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                SimmeringPotAnimation()
                    .frame(width: 160, height: 160)

                Text(Self.messages[messageIndex])
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textDark)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
                    .id(messageIndex)
                    .padding(.horizontal, Theme.Spacing.xl)
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_800_000_000)
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    messageIndex = (messageIndex + 1) % Self.messages.count
                }
            }
        }
    }
}

#Preview {
    RecipeGeneratingOverlay()
}
