//
//  LaunchAnimationView.swift
//  Simmr
//
//  Brief launch reveal: the "S" fades and scales in near the bottom of the
//  screen, settles centered, then the rest of the word types in one letter
//  at a time. The whole word stays centered at every step, so each new
//  letter pushes the word to re-center rather than the "S" sitting fixed
//  in its final spot while the rest fades in beside it.
//

import SwiftUI

struct LaunchAnimationView: View {
    let onComplete: () -> Void

    @State private var phase: Phase = .initial
    @State private var revealedCount: Int = 1

    private enum Phase {
        case initial, revealing
    }

    private static let fullWord = "Simmr"
    private static let letterStagger: UInt64 = 130_000_000

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Theme.Colors.creamBackground.ignoresSafeArea()

                Text(String(Self.fullWord.prefix(revealedCount)))
                    .font(splashFont)
                    .foregroundStyle(Theme.Colors.coral)
                    .contentTransition(.interpolate)
                    .scaleEffect(phase == .initial ? 0.5 : 1)
                    .opacity(phase == .initial ? 0 : 1)
                    .offset(y: phase == .initial ? geometry.size.height * 0.25 : 0)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .task { await runAnimation() }
    }

    private var splashFont: Font {
        .custom(Theme.Typography.FontName.extraBold, size: 64)
    }

    private func runAnimation() async {
        withAnimation(.easeOut(duration: 0.5)) {
            phase = .revealing
        }
        try? await Task.sleep(nanoseconds: 550_000_000)

        for count in 2...Self.fullWord.count {
            withAnimation(.easeOut(duration: 0.22)) {
                revealedCount = count
            }
            try? await Task.sleep(nanoseconds: Self.letterStagger)
        }

        try? await Task.sleep(nanoseconds: 300_000_000)
        onComplete()
    }
}

#Preview {
    LaunchAnimationView {}
}
