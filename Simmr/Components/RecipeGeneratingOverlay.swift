//
//  RecipeGeneratingOverlay.swift
//  Simmr
//
//  Full-screen loader shown while a recipe is being parsed, with a
//  simmering-pot animation. Two modes:
//  - Default (no `progress`): cycles cosmetic status messages on a timer —
//    used by the paste-text flow, unchanged from before.
//  - `progress: .readingImages`: shows a real determinate progress bar,
//    since OCR runs locally and we know exactly how far along it is. Used
//    by the photo/camera import flow while reading images; once it moves
//    to `.parsingRecipe` (the single, non-streamed OpenAI call has no real
//    progress to report) it falls back to the same cosmetic cycling as the
//    default mode, just with import-flavored `messages`.
//

import SwiftUI

struct RecipeGeneratingOverlay: View {
    private static let defaultMessages = [
        "Analysing your recipe…",
        "Breaking down the steps…",
        "Estimating quantities…",
        "Optimising the cooking order…",
        "Personalising to your taste…",
        "Almost ready…",
    ]

    var progress: ImportPhase?
    var messages: [String] = RecipeGeneratingOverlay.defaultMessages

    @State private var messageIndex = 0

    var body: some View {
        ZStack {
            Theme.Colors.creamBackground.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                SimmeringPotAnimation()
                    .frame(width: 160, height: 160)

                if case .readingImages(let done, let total) = progress {
                    VStack(spacing: Theme.Spacing.sm) {
                        Text(done < total ? "Reading images…" : "Extracting text…")
                            .font(Theme.Typography.headline)
                            .foregroundStyle(Theme.Colors.textDark)
                            .transition(.opacity)

                        ProgressView(value: Double(done), total: Double(max(total, 1)))
                            .tint(Theme.Colors.coral)
                            .frame(width: 200)

                        Text("\(done) of \(total)")
                            .font(Theme.Typography.footnote)
                            .foregroundStyle(Theme.Colors.textMuted)
                    }
                } else {
                    Text(messages[messageIndex])
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.textDark)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                        .id(messageIndex)
                        .padding(.horizontal, Theme.Spacing.xl)
                }
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_800_000_000)
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    messageIndex = (messageIndex + 1) % messages.count
                }
            }
        }
    }
}

#Preview {
    RecipeGeneratingOverlay()
}
