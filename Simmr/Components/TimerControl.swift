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
//  Deliberately lightweight by design: every action (Start/Pause/Reset/
//  Continue/Restart) is a small pill button, not a full-width one — the
//  timer is a helper alongside the recipe content, not the screen's main
//  focus. See CookingModeView, which docks Previous/Next as floating
//  circular buttons instead of stacking full-width nav under this card, for
//  the same reason.
//

import AVFoundation
import SwiftUI
import UIKit

private let hourglassFlipDuration: Double = 0.75
/// Below this many seconds remaining, the sand-flow and breathing animations
/// speed up so the final stretch always reads as visibly more urgent.
private let urgentThresholdSeconds = 5
/// Fixed content width of the timer card — sized to comfortably fit its
/// widest state (Complete's "Continue"/"Restart" pill pair) with room to
/// spare, so the card never visibly resizes as it moves between idle,
/// running, paused, and complete.
private let timerCardWidth: CGFloat = 280
/// Fixed height of the row below the hourglass/time display — see the
/// comment where it's applied for why.
private let timerControlRowHeight: CGFloat = 58

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

    private var isUrgent: Bool {
        isRunning && remaining > 0 && remaining <= urgentThresholdSeconds
    }

    @State private var glowOpacity: Double = 0
    @State private var wobbleAngle: Double = 0
    @State private var textPopScale: Double = 1
    @State private var showCompletionContent = false
    @State private var showFinishedBanner = false
    @State private var didCelebrate = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var flipStartDate: Date?
    /// Decorative "kick" spin around the vertical axis, played once on Start
    /// or plain Reset — distinct from `flipStartDate`'s 180° tumble, which
    /// only looks correct swapping a fully-settled top/bottom (Restart, from
    /// Complete). A mid-run partial fill doesn't have that symmetry, so
    /// Start/Reset get a lighter spin flourish instead of a literal tumble.
    @State private var spinDegrees: Double = 0

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
                            .scaleEffect(textPopScale)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)

                        stepperButton(systemImage: "plus", action: onIncrementMinute, isEnabled: true)
                    }
                }
            }

            controlRow
                // Fixed height too, for the same reason as timerCardWidth
                // below — Idle/Complete's pill row and the running/paused
                // circular-buttons-with-labels row are naturally different
                // heights, so without this the whole card would grow/shrink
                // vertically as the timer moves between states. Centering
                // within this fixed slot replaces the per-branch top-padding
                // this used to have, so spacing above the shorter rows stays
                // consistent instead of compounding with it.
                .frame(height: timerControlRowHeight)
        }
        // Fixed width, not hug-content — Idle's single "Start" pill, the
        // running/paused pair of circular icon buttons, and Complete's
        // "Continue"/"Restart" pills are all different natural widths, and
        // a hug-content card would visibly resize every time the state
        // changes. Pinning it here instead keeps the card's footprint
        // constant; the VStack's default center alignment centers whichever
        // row is narrower than this within it.
        .frame(width: timerCardWidth)
        .padding(Theme.Spacing.sm)
        .background(Theme.Colors.creamCard)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .strokeBorder(Theme.Colors.border, lineWidth: Theme.Stroke.hairline)
        )
        .overlay(alignment: .top) {
            if showFinishedBanner {
                finishedBanner
                    .offset(y: -20)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
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
                isUrgent: isUrgent,
                flipStartDate: flipStartDate
            )
            .frame(width: 42, height: isRunning ? 58 : 54)
            .rotationEffect(.degrees(wobbleAngle))
            .rotation3DEffect(.degrees(spinDegrees), axis: (x: 0, y: 1, z: 0))
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

    private var finishedBanner: some View {
        HStack(spacing: Theme.Spacing.xxs) {
            Image(systemName: "bell.fill")
            Text("Timer Finished")
        }
        .font(Theme.Typography.footnote.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.xs)
        .background(Theme.Colors.coral)
        .clipShape(Capsule())
        .shadow(color: Theme.Colors.textDark.opacity(0.25), radius: 8, x: 0, y: 3)
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

    /// True once a timer has been started and then paused (some time has
    /// elapsed), as opposed to never having been touched this step — both
    /// present as `isRunning == false, isComplete == false` to this view,
    /// but only the former should offer Resume+Reset instead of Start.
    /// `progress` is exactly 0 only in the untouched-idle case (see
    /// CookingModeViewModel.timerProgress), so it's a reliable signal
    /// without needing a dedicated prop.
    private var isPaused: Bool {
        !isRunning && !isComplete && progress > 0
    }

    @ViewBuilder
    private var controlRow: some View {
        if isComplete {
            HStack(spacing: Theme.Spacing.sm) {
                Button(action: onContinue) {
                    Label("Continue", systemImage: "arrow.right")
                }
                .buttonStyle(CompactPillButtonStyle(isProminent: true))

                Button(action: restartTimer) {
                    Label("Restart", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(CompactPillButtonStyle(isProminent: false))
            }
        } else if isRunning || isPaused {
            HStack(spacing: Theme.Spacing.lg) {
                if isRunning {
                    circularActionButton(systemImage: "pause.fill", label: "Pause", isProminent: true, action: onPause)
                } else {
                    circularActionButton(systemImage: "play.fill", label: "Resume", isProminent: true) {
                        spinAndPerform(onStart)
                    }
                }
                circularActionButton(systemImage: "arrow.counterclockwise", label: "Reset", isProminent: false) {
                    spinAndPerform(onReset)
                }
            }
        } else {
            Button(action: { spinAndPerform(onStart) }) {
                Label("Start", systemImage: "play.fill")
            }
            .buttonStyle(CompactPillButtonStyle(isProminent: true))
            .frame(minWidth: 130)
        }
    }

    /// Small circular icon button with a caption underneath — used for
    /// Pause/Resume and Reset while a timer is running or paused, so they
    /// read as a lightweight, connected control cluster rather than a row
    /// of large standalone buttons.
    private func circularActionButton(systemImage: String, label: String, isProminent: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.xxs) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isProminent ? .white : Theme.Colors.textDark)
                    .frame(width: 40, height: 40)
                    .background(isProminent ? Theme.Colors.coral : Theme.Colors.creamBackground)
                    .overlay(
                        Circle().strokeBorder(isProminent ? Color.clear : Theme.Colors.border, lineWidth: Theme.Stroke.hairline)
                    )
                    .clipShape(Circle())

                Text(label)
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(Theme.Colors.textMuted)
            }
        }
        .buttonStyle(.plain)
    }

    private var formattedTime: String {
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Start / Reset spin

    /// Plays the lighter "kick" spin (see `spinDegrees`'s doc comment) and
    /// then performs the actual state change — shared by Start and the
    /// running state's Reset, the two actions that begin a fresh countdown
    /// from a state where a literal chamber-swap tumble wouldn't read
    /// correctly.
    private func spinAndPerform(_ action: () -> Void) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
            spinDegrees += 360
        }
        action()
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

    /// One-shot: a brief pause, 2-3 quick shakes with a bouncing timer text,
    /// a bell chime, a strong haptic, a soft coral glow, and a transient
    /// "Timer Finished" banner — before settling into the checkmark +
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
            withAnimation(.spring(response: 0.16, dampingFraction: 0.3)) {
                wobbleAngle = 9
            }
            withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                textPopScale = 1.3
            }
            try? await Task.sleep(nanoseconds: 110_000_000)
            withAnimation(.spring(response: 0.17, dampingFraction: 0.3)) {
                wobbleAngle = -8
            }
            try? await Task.sleep(nanoseconds: 110_000_000)
            withAnimation(.spring(response: 0.17, dampingFraction: 0.32)) {
                wobbleAngle = 6
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
            withAnimation(.spring(response: 0.22, dampingFraction: 0.42)) {
                wobbleAngle = 0
                textPopScale = 1
            }

            UINotificationFeedbackGenerator().notificationOccurred(.success)

            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showFinishedBanner = true
            }

            try? await Task.sleep(nanoseconds: 200_000_000)
            withAnimation(.easeOut(duration: 0.6)) {
                glowOpacity = 0
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showCompletionContent = true
            }

            try? await Task.sleep(nanoseconds: 2_300_000_000)
            withAnimation(.easeOut(duration: 0.35)) {
                showFinishedBanner = false
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

/// Small pill button used for every timer action (Start/Pause/Reset/
/// Continue/Restart) — deliberately not full-width, so the timer card never
/// reads as the screen's dominant element the way a full-width primary
/// button would.
private struct CompactPillButtonStyle: ButtonStyle {
    let isProminent: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.footnote.weight(.semibold))
            .foregroundStyle(isProminent ? .white : Theme.Colors.textDark)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                Capsule().fill(isProminent ? Theme.Colors.coral.opacity(configuration.isPressed ? 0.85 : 1) : Theme.Colors.creamBackground)
            )
            .overlay(
                Capsule().strokeBorder(isProminent ? Color.clear : Theme.Colors.border, lineWidth: Theme.Stroke.hairline)
            )
    }
}

/// The custom-drawn hourglass itself — top chamber draining, bottom chamber
/// filling, with a falling sand stream and a subtle breathe/rock while
/// running (both speeding up once `isUrgent`), and a manual 180° tumble for
/// the restart flip. Rendered as a single static `Canvas` when nothing is
/// animating (idle/paused/complete) to avoid any unnecessary redraw work,
/// and only switches to `TimelineView(.animation)` while running or
/// mid-flip.
private struct HourglassView: View {
    let topFraction: Double
    let isAnimating: Bool
    let isUrgent: Bool
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
        let period = isUrgent ? 1.1 : 2.0
        return 1 + 0.025 * sin(date.timeIntervalSinceReferenceDate * 2 * .pi / period)
    }

    private func rockAngle(date: Date) -> Double {
        let period = isUrgent ? 1.4 : 2.6
        let amplitude = isUrgent ? 3.0 : 2.2
        return amplitude * sin(date.timeIntervalSinceReferenceDate * 2 * .pi / period + 0.7)
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
                let p = (phase * 3.8 + Double(i) * 0.33).truncatingRemainder(dividingBy: 1)
                let y = neckY + (streamBottom - neckY) * p
                let grain = Path(ellipseIn: CGRect(x: midX - 1.2, y: y, width: 2.4, height: 2.4))
                context.fill(grain, with: .color(Theme.Colors.amber.opacity(0.85)))
            }
        } else if isAnimating, f > 0.01, g < 0.99 {
            // A brisk, clearly-visible pour: bigger/brighter grains than a
            // subtle trickle, a solid (not faint) connecting stream, and
            // both speeding up further once isUrgent kicks in.
            let fallSpeed = isUrgent ? 4.5 : 2.4
            let streamBottom = max(neckY + 2, bottomFillY0)
            for i in 0..<3 {
                let p = (phase * fallSpeed + Double(i) * 0.33).truncatingRemainder(dividingBy: 1)
                let y = neckY + (streamBottom - neckY) * p
                let grain = Path(ellipseIn: CGRect(x: midX - 1.3, y: y, width: 2.6, height: 2.6))
                context.fill(grain, with: .color(Theme.Colors.amber.opacity(0.95)))
            }
            var streamLine = Path()
            streamLine.move(to: CGPoint(x: midX, y: neckY))
            streamLine.addLine(to: CGPoint(x: midX, y: streamBottom))
            context.stroke(streamLine, with: .color(Theme.Colors.amber.opacity(0.55)), lineWidth: 1.6)
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

#Preview("Urgent") {
    TimerControl(
        remaining: 4,
        progress: 0.98,
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
