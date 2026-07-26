//
//  TimerControl.swift
//  Simmr
//
//  A compact hourglass kitchen timer, sized to stay out of the recipe's way.
//  The hourglass is drawn entirely with Canvas/TimelineView — no images, no
//  Lottie. Everything renders as a pure function of `remaining`/`progress`
//  (both derived from CookingModeViewModel's wall-clock timerEndDate), never
//  from an independent animation clock — so the sand level is always
//  mathematically correct no matter when this view was recreated, which is
//  what makes "restore its exact state" work for free after the app
//  backgrounds/foregrounds. The one exception is the manual restart flip,
//  which needs its own short-lived clock since it isn't a function of the
//  timer's own progress — that's handled by `flipStartDate` + a dedicated
//  Task, decoupled from rendering.
//

import AVFoundation
import SwiftUI
import UIKit

private let hourglassFlipDuration: Double = 0.9

struct TimerControl: View {
    let remaining: Int
    /// Elapsed fraction, 0 at the start of the current timer, 1 at
    /// completion — supplied by CookingModeViewModel's timerProgress.
    let progress: Double
    let isRunning: Bool
    let isComplete: Bool
    let canDecreaseMinute: Bool
    let onStart: () -> Void
    let onPause: () -> Void
    let onReset: () -> Void
    let onIncrementMinute: () -> Void
    let onDecrementMinute: () -> Void
    let onContinue: () -> Void

    /// Fraction of sand still remaining in the top chamber — 1 at the start
    /// of the timer, 0 at completion. Frozen at 0 for the entire duration of
    /// a restart flip (see `flipStartDate`), since the flip only rotates the
    /// already-settled "finished" sand rather than re-simulating it pouring.
    private var topFraction: Double {
        max(0, min(1, 1 - progress))
    }

    @State private var glowOpacity: Double = 0
    @State private var wobbleAngle: Double = 0
    @State private var showCompletionContent = false
    @State private var didCelebrate = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var flipStartDate: Date?

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.md) {
                hourglass

                if showCompletionContent {
                    completionLabel
                } else {
                    HStack(spacing: Theme.Spacing.sm) {
                        stepperButton(systemImage: "minus", action: onDecrementMinute, isEnabled: canDecreaseMinute)

                        Text(formattedTime)
                            .font(Theme.Typography.timerDisplay)
                            .foregroundStyle(Theme.Colors.textDark)
                            .monospacedDigit()
                            .contentTransition(.numericText(countsDown: true))
                            .animation(.snappy(duration: 0.35), value: remaining)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)

                        stepperButton(systemImage: "plus", action: onIncrementMinute, isEnabled: true)
                    }
                }

                Spacer(minLength: 0)
            }

            controlRow
        }
        .padding(Theme.Spacing.sm)
        .background(Theme.Colors.creamCard)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .strokeBorder(Theme.Colors.border, lineWidth: Theme.Stroke.hairline)
        )
        .onAppear {
            if isComplete {
                didCelebrate = true
                showCompletionContent = true
            }
        }
        .onChange(of: isComplete) { _, newValue in
            if newValue, !didCelebrate {
                didCelebrate = true
                celebrate()
            } else if !newValue {
                didCelebrate = false
                showCompletionContent = false
            }
        }
    }

    // MARK: - Hourglass

    private var hourglass: some View {
        ZStack {
            Circle()
                .fill(Theme.Colors.coral)
                .opacity(glowOpacity)
                .blur(radius: 20)
                .frame(width: 90, height: 90)

            HourglassView(
                topFraction: topFraction,
                isAnimating: isRunning,
                flipStartDate: flipStartDate
            )
            .frame(width: 42, height: isRunning ? 58 : 54)
            .rotationEffect(.degrees(wobbleAngle))
        }
        .frame(width: 56, height: 62)
    }

    @ViewBuilder
    private var completionLabel: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: Theme.Spacing.xxs) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.Colors.amber)
                Text("Time's Up")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textDark)
            }
        }
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Controls

    private func stepperButton(systemImage: String, action: @escaping () -> Void, isEnabled: Bool) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isEnabled ? Theme.Colors.textDark : Theme.Colors.textMuted)
                .frame(width: 26, height: 26)
                .background(Theme.Colors.creamBackground)
                .overlay(
                    Circle().strokeBorder(Theme.Colors.border, lineWidth: Theme.Stroke.hairline)
                )
                .clipShape(Circle())
        }
        .disabled(!isEnabled)
    }

    @ViewBuilder
    private var controlRow: some View {
        if isComplete {
            VStack(spacing: Theme.Spacing.xs) {
                Button("Continue", action: onContinue)
                    .buttonStyle(.primary)
                Button("Restart Timer", action: restartTimer)
                    .buttonStyle(.secondary)
            }
        } else if isRunning {
            HStack(spacing: Theme.Spacing.sm) {
                Button("Pause", action: onPause)
                    .buttonStyle(.secondary)
                Button("Reset", action: onReset)
                    .buttonStyle(.secondary)
            }
        } else {
            Button("Start Timer", action: onStart)
                .buttonStyle(.primary)
        }
    }

    private var formattedTime: String {
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Restart flip

    /// Runs the signature 180° restart flip: the already-settled, empty-on-
    /// top hourglass tumbles over (a pure rotation of the frozen "finished"
    /// sand — which is exactly what makes it land full-on-top afterward,
    /// since flipping an empty-top/full-bottom glass by 180° visually swaps
    /// which chamber is on top), then starts a fresh countdown. The
    /// completion of the flip is driven by its own Task, not by the render
    /// loop, so it fires exactly once regardless of frame timing.
    private func restartTimer() {
        flipStartDate = Date()
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(hourglassFlipDuration * 1_000_000_000))
            flipStartDate = nil
            onReset()
            onStart()
        }
    }

    // MARK: - Completion celebration

    /// One-shot: a brief pause, a subtle wobble, a bell chime, a strong
    /// haptic, and a soft coral glow — before settling into the checkmark +
    /// "Time's Up" state. Guarded by `didCelebrate` so a view recreated
    /// while already complete never replays this.
    private func celebrate() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)

            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            playBellSound()

            withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
                glowOpacity = 0.5
            }
            withAnimation(.spring(response: 0.18, dampingFraction: 0.32)) {
                wobbleAngle = 7
            }
            try? await Task.sleep(nanoseconds: 130_000_000)
            withAnimation(.spring(response: 0.2, dampingFraction: 0.3)) {
                wobbleAngle = -6
            }
            try? await Task.sleep(nanoseconds: 130_000_000)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                wobbleAngle = 0
            }

            UINotificationFeedbackGenerator().notificationOccurred(.success)

            try? await Task.sleep(nanoseconds: 200_000_000)
            withAnimation(.easeOut(duration: 0.6)) {
                glowOpacity = 0
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showCompletionContent = true
            }
        }
    }

    private func playBellSound() {
        guard let url = Bundle.main.url(forResource: "TimerCompleteBell", withExtension: "wav") else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        audioPlayer = try? AVAudioPlayer(contentsOf: url)
        audioPlayer?.play()
    }
}

/// The custom-drawn hourglass itself — top chamber draining, bottom chamber
/// filling, with a falling sand stream and a subtle breathe/rock while
/// running, and a manual 180° tumble for the restart flip. Rendered as a
/// single static `Canvas` when nothing is animating (idle/paused/complete)
/// to avoid any unnecessary redraw work, and only switches to
/// `TimelineView(.animation)` while running or mid-flip.
private struct HourglassView: View {
    let topFraction: Double
    let isAnimating: Bool
    let flipStartDate: Date?

    var body: some View {
        if isAnimating || flipStartDate != nil {
            TimelineView(.animation) { context in
                rendered(date: context.date)
            }
        } else {
            rendered(date: Date())
        }
    }

    @ViewBuilder
    private func rendered(date: Date) -> some View {
        let isFlipping = flipStartDate != nil
        let t = flipT(at: date)

        Canvas { context, size in
            draw(context: context, size: size, date: date, isFlipping: isFlipping)
        }
        .rotation3DEffect(.degrees(t * 180), axis: (x: 1, y: 0, z: 0), perspective: 0.4)
        .scaleEffect(isAnimating && !isFlipping ? breatheScale(date: date) : 1)
        .rotationEffect(.degrees(isAnimating && !isFlipping ? rockAngle(date: date) : 0))
    }

    private func flipT(at date: Date) -> Double {
        guard let start = flipStartDate else { return 0 }
        let elapsed = date.timeIntervalSince(start)
        return max(0, min(1, elapsed / hourglassFlipDuration))
    }

    private func breatheScale(date: Date) -> CGFloat {
        1 + 0.02 * sin(date.timeIntervalSinceReferenceDate * 2 * .pi / 2.6)
    }

    private func rockAngle(date: Date) -> Double {
        2.0 * sin(date.timeIntervalSinceReferenceDate * 2 * .pi / 3.4 + 0.7)
    }

    private func draw(context: GraphicsContext, size: CGSize, date: Date, isFlipping: Bool) {
        let w = size.width
        let h = size.height
        let capHeight = h * 0.055
        let neckGap = max(2, w * 0.16)
        let neckY = h / 2
        let inset = w * 0.05
        let leftX = inset
        let rightX = w - inset
        let midX = w / 2

        var outline = Path()
        outline.move(to: CGPoint(x: leftX, y: capHeight))
        outline.addLine(to: CGPoint(x: rightX, y: capHeight))
        outline.addLine(to: CGPoint(x: midX + neckGap / 2, y: neckY))
        outline.addLine(to: CGPoint(x: rightX, y: h - capHeight))
        outline.addLine(to: CGPoint(x: leftX, y: h - capHeight))
        outline.addLine(to: CGPoint(x: midX - neckGap / 2, y: neckY))
        outline.closeSubpath()

        context.fill(outline, with: .color(Theme.Colors.creamCard))

        context.fill(
            RoundedRectangle(cornerRadius: capHeight / 2).path(in: CGRect(x: 0, y: 0, width: w, height: capHeight)),
            with: .color(Theme.Colors.textDark.opacity(0.7))
        )
        context.fill(
            RoundedRectangle(cornerRadius: capHeight / 2).path(in: CGRect(x: 0, y: h - capHeight, width: w, height: capHeight)),
            with: .color(Theme.Colors.textDark.opacity(0.7))
        )

        let topBulbHeight = neckY - capHeight
        let topHalfWidth = (rightX - leftX) / 2
        let f = topFraction

        if f > 0.01 {
            let sandHeight = topBulbHeight * f
            let sandHalfWidth = topHalfWidth * f
            var topSand = Path()
            topSand.move(to: CGPoint(x: midX, y: neckY))
            topSand.addLine(to: CGPoint(x: midX - sandHalfWidth, y: neckY - sandHeight))
            topSand.addLine(to: CGPoint(x: midX + sandHalfWidth, y: neckY - sandHeight))
            topSand.closeSubpath()
            context.fill(topSand, with: .color(Theme.Colors.amber))
        }

        let bottomBulbHeight = (h - capHeight) - neckY
        let bottomHalfWidth = (rightX - leftX) / 2
        let g = 1 - f
        var bottomFillY0 = h - capHeight

        if g > 0.01 {
            let y0 = (h - capHeight) - bottomBulbHeight * g
            let halfWidth0 = bottomHalfWidth * (1 - g)
            bottomFillY0 = y0
            var bottomSand = Path()
            bottomSand.move(to: CGPoint(x: midX - halfWidth0, y: y0))
            bottomSand.addLine(to: CGPoint(x: midX + halfWidth0, y: y0))
            bottomSand.addLine(to: CGPoint(x: rightX, y: h - capHeight))
            bottomSand.addLine(to: CGPoint(x: leftX, y: h - capHeight))
            bottomSand.closeSubpath()
            context.fill(bottomSand, with: .color(Theme.Colors.amber))
        }

        let phase = date.timeIntervalSinceReferenceDate
        if isFlipping {
            // Purely decorative: the flip itself is a rotation of the
            // already-settled sand (see restartTimer's doc comment), so this
            // is just a few grains dancing near the neck for the sense of
            // motion the spec asks for during the tumble.
            let streamBottom = neckY + h * 0.14
            for i in 0..<3 {
                let p = (phase * 3.2 + Double(i) * 0.33).truncatingRemainder(dividingBy: 1)
                let y = neckY + (streamBottom - neckY) * p
                let grain = Path(ellipseIn: CGRect(x: midX - 1, y: y, width: 2, height: 2))
                context.fill(grain, with: .color(Theme.Colors.amber.opacity(0.85)))
            }
        } else if isAnimating, f > 0.01, g < 0.99 {
            let streamBottom = max(neckY + 2, bottomFillY0)
            for i in 0..<3 {
                let p = (phase * 1.7 + Double(i) * 0.33).truncatingRemainder(dividingBy: 1)
                let y = neckY + (streamBottom - neckY) * p
                let grain = Path(ellipseIn: CGRect(x: midX - 1, y: y, width: 2, height: 2))
                context.fill(grain, with: .color(Theme.Colors.amber.opacity(0.9)))
            }
            var streamLine = Path()
            streamLine.move(to: CGPoint(x: midX, y: neckY))
            streamLine.addLine(to: CGPoint(x: midX, y: streamBottom))
            context.stroke(streamLine, with: .color(Theme.Colors.amber.opacity(0.3)), lineWidth: 1)
        }

        context.stroke(outline, with: .color(Theme.Colors.textDark.opacity(0.5)), lineWidth: 1.5)
    }
}

#Preview("Idle") {
    TimerControl(
        remaining: 300,
        progress: 0,
        isRunning: false,
        isComplete: false,
        canDecreaseMinute: false,
        onStart: {}, onPause: {}, onReset: {}, onIncrementMinute: {}, onDecrementMinute: {}, onContinue: {}
    )
    .padding()
    .background(Theme.Colors.creamBackground)
}

#Preview("Running") {
    TimerControl(
        remaining: 95,
        progress: 0.47,
        isRunning: true,
        isComplete: false,
        canDecreaseMinute: true,
        onStart: {}, onPause: {}, onReset: {}, onIncrementMinute: {}, onDecrementMinute: {}, onContinue: {}
    )
    .padding()
    .background(Theme.Colors.creamBackground)
}

#Preview("Complete") {
    TimerControl(
        remaining: 0,
        progress: 1,
        isRunning: false,
        isComplete: true,
        canDecreaseMinute: true,
        onStart: {}, onPause: {}, onReset: {}, onIncrementMinute: {}, onDecrementMinute: {}, onContinue: {}
    )
    .padding()
    .background(Theme.Colors.creamBackground)
}
