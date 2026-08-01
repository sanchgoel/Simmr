//
//  CookingLiveActivityWidget.swift
//  SimmrWidget
//
//  Renders Cooking Mode's Live Activity: Lock Screen card plus the three
//  Dynamic Island presentations. All content comes from
//  CookingActivityAttributes.ContentState, pushed by LiveActivityManager
//  in the main app — this file never talks back to the app directly.
//

import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct CookingLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CookingActivityAttributes.self) { context in
            if context.state.isFinished {
                FinishedLockScreenView(attributes: context.attributes)
            } else {
                LockScreenView(state: context.state)
            }
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    if !context.state.isFinished {
                        Text("🍳")
                            .font(.title2)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if !context.state.isFinished {
                        TimerBadge(state: context.state, font: .headline)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    if context.state.isFinished {
                        FinishedIslandView(attributes: context.attributes)
                    } else {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.state.stepTitle)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(WidgetTheme.islandTextPrimary)
                                .lineLimit(1)
                                .contentTransition(.opacity)
                            Text("Step \(context.state.stepNumber) of \(context.state.totalSteps)")
                                .font(.caption2)
                                .foregroundStyle(WidgetTheme.islandTextMuted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .animation(.easeInOut(duration: 0.3), value: context.state.currentStepIndex)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.isFinished {
                        EmptyView()
                    } else {
                        ActionRow(
                            state: context.state,
                            mutedTint: WidgetTheme.islandTextMuted,
                            accentTint: WidgetTheme.coral
                        )
                    }
                }
            } compactLeading: {
                Text(context.state.isFinished ? "🎉" : "🍳")
                    .font(.system(size: 15))
            } compactTrailing: {
                if context.state.isFinished {
                    Text("🎉")
                        .font(.system(size: 15))
                } else {
                    TimerBadge(state: context.state, font: .caption2.monospacedDigit(), compact: true)
                }
            } minimal: {
                // The minimal presentation only appears when another Live
                // Activity is competing for space, and Apple's own
                // convention is a single glyph there — the timer is the
                // more useful of the two at that size, so it's shown alone.
                if context.state.isFinished {
                    Text("🎉")
                        .font(.system(size: 15))
                } else {
                    TimerBadge(state: context.state, font: .caption2.monospacedDigit(), compact: true)
                }
            }
        }
    }
}

/// Deep link opened by the finished card's "Rate it" tap — routes straight
/// to the post-cooking feedback flow for this session, whether or not the
/// app is still alive. See SimmrApp.onOpenURL / DeepLinkRouter.
private func feedbackURL(sessionID: UUID) -> URL {
    URL(string: "simmr://feedback?sessionID=\(sessionID.uuidString)")!
}

/// The timer/step-count glyph shown in the Dynamic Island's trailing,
/// compact, and minimal presentations — whichever of "live countdown",
/// "paused time", or "step count" currently applies. Always coral, which
/// reads fine on both the Lock Screen and the Dynamic Island's black
/// cutout.
private struct TimerBadge: View {
    let state: CookingActivityAttributes.ContentState
    let font: Font
    var compact: Bool = false

    var body: some View {
        Group {
            if state.isTimerComplete {
                Text("✅")
            } else if let endDate = state.timerEndDate {
                // showsHours: false caps this to a fixed "MM:SS" footprint.
                // Text(timerInterval:) otherwise reserves layout width for
                // the widest format it could ever need mid-countdown
                // (including an hours digit for longer timers), which blew
                // up the whole Dynamic Island pill once its width cap was
                // removed to fix the earlier cropping bug.
                Text(timerInterval: Self.safeRange(to: endDate), countsDown: true, showsHours: false)
            } else if let remaining = state.pausedRemainingSeconds {
                Text(Self.formattedTime(remaining))
            } else {
                Text("\(state.stepNumber)/\(state.totalSteps)")
            }
        }
        .font(font)
        .foregroundStyle(WidgetTheme.coral)
        .lineLimit(1)
        .padding(.horizontal, compact ? 2 : 6)
        .animation(.easeInOut(duration: 0.25), value: state.currentStepIndex)
        .animation(.easeInOut(duration: 0.25), value: state.isTimerComplete)
    }

    private static func safeRange(to endDate: Date) -> ClosedRange<Date> {
        let now = Date()
        return now...max(endDate, now.addingTimeInterval(1))
    }

    private static func formattedTime(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

/// Interactive Previous/Next/Finish row. Each button invokes a
/// `LiveActivityIntent` (PreviousStepIntent, NextStepIntent,
/// FinishRecipeIntent) that runs in this extension's process and updates
/// the running Activity directly — no app launch needed. See
/// CookingSessionManager for how the Activity stays the shared source of
/// truth the app also observes. Shown on both the Lock Screen and the
/// Dynamic Island's expanded presentation — colors are passed in explicitly
/// since the Lock Screen adapts to system appearance while the Dynamic
/// Island is always dark-style.
private struct ActionRow: View {
    let state: CookingActivityAttributes.ContentState
    let mutedTint: Color
    let accentTint: Color

    var body: some View {
        HStack(spacing: 8) {
            if !state.isFirstStep, let previous = state.previousStepTitle {
                Button(intent: PreviousStepIntent()) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(previous).lineLimit(1)
                    }
                }
                .buttonStyle(FilledButtonStyle(fill: mutedTint))
            } else {
                Spacer(minLength: 0)
            }

            Spacer(minLength: 12)

            if state.isLastStep {
                Button(intent: FinishRecipeIntent()) {
                    Text("🍽 Finish Recipe")
                        .lineLimit(1)
                }
                .buttonStyle(FilledButtonStyle(fill: accentTint))
            } else if let next = state.nextStepTitle {
                Button(intent: NextStepIntent()) {
                    HStack(spacing: 4) {
                        Text(next).lineLimit(1)
                        Image(systemName: "chevron.right")
                    }
                }
                .buttonStyle(FilledButtonStyle(fill: accentTint))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .font(.caption.weight(.semibold))
        .animation(.easeInOut(duration: 0.3), value: state.currentStepIndex)
    }
}

/// Solid fill with white text, using an explicit `Capsule().fill(_:)`
/// rather than `.tint()` + a system button style — the latter applies its
/// own automatic shade/material blending, which read as a muddy dark
/// orange instead of the true brand coral.
private struct FilledButtonStyle: ButtonStyle {
    let fill: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(fill))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

/// Slim capsule progress track spanning the full card width — no
/// percentage label, just a glanceable sense of "how far along."
private struct ProgressBar: View {
    let progress: CGFloat
    let trackColor: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(trackColor)
                Capsule()
                    .fill(WidgetTheme.coral)
                    .frame(width: max(4, geometry.size.width * progress))
            }
        }
        .frame(height: 4)
        .animation(.easeInOut(duration: 0.35), value: progress)
    }
}

/// Step-count-plus-timer row. Uses the same `GeometryReader`-measured-width
/// technique as `ProgressBar` — the only approach in this file that
/// reliably learns the card's true content width in ActivityKit's Lock
/// Screen rendering. Plain `.frame(maxWidth: .infinity)` doesn't expand
/// here, and a `PreferenceKey` round-trip through `@State` never resolves
/// in time, since the Lock Screen renders as a single static snapshot
/// rather than through SwiftUI's normal multi-pass reactive re-render loop.
/// `GeometryReader` sidesteps both because it measures and uses the width
/// within the very same render pass.
private struct StepRow: View {
    let stepNumber: Int
    let totalSteps: Int
    let mutedColor: Color
    @ViewBuilder let timer: () -> AnyView

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Step \(stepNumber) of \(totalSteps)")
                    .font(.caption)
                    .foregroundStyle(mutedColor)

                Spacer(minLength: 8)

                timer()
            }
            .frame(width: geometry.size.width, alignment: .leading)
        }
        .frame(height: 20)
    }
}

private struct LockScreenView: View {
    let state: CookingActivityAttributes.ContentState

    private var progress: CGFloat {
        guard state.totalSteps > 0 else { return 0 }
        return CGFloat(state.stepNumber) / CGFloat(state.totalSteps)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ProgressBar(progress: progress, trackColor: WidgetTheme.textMuted.opacity(0.18))

            Text(state.stepTitle)
                .font(.title3.weight(.bold))
                .foregroundStyle(WidgetTheme.textDark)
                .lineLimit(1)
                .contentTransition(.opacity)

            StepRow(
                stepNumber: state.stepNumber,
                totalSteps: state.totalSteps,
                mutedColor: WidgetTheme.textMuted,
                timer: { AnyView(timerTrailing) }
            )

            Text(state.instruction)
                .font(.subheadline)
                .foregroundStyle(WidgetTheme.textDark.opacity(0.8))
                .lineLimit(2)

            ActionRow(
                state: state,
                mutedTint: WidgetTheme.textMuted,
                accentTint: WidgetTheme.coral
            )
            .padding(.top, 2)
        }
        .padding(16)
        .activityBackgroundTint(WidgetTheme.creamBackground)
        .activitySystemActionForegroundColor(WidgetTheme.textDark)
        .animation(.easeInOut(duration: 0.3), value: state.currentStepIndex)
        .animation(.easeInOut(duration: 0.25), value: state.isTimerComplete)
    }

    /// Reserves a stable width for whichever timer state is showing, so the
    /// title's `.frame(maxWidth: .infinity)` has a fixed amount to subtract
    /// and the badge lands flush against the trailing edge. Deliberately
    /// not `.fixedSize()` — that forces a synchronous ideal-size query which
    /// conflicts with `Text(timerInterval:)`'s OS-managed background
    /// updates and made the countdown render as a stuck loading glyph.
    @ViewBuilder
    private var timerTrailing: some View {
        if state.isTimerComplete {
            HStack(spacing: 4) {
                Text("✅")
                Text("Done")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(WidgetTheme.textDark)
            .frame(minWidth: 100, alignment: .trailing)
        } else if let endDate = state.timerEndDate {
            HStack(spacing: 4) {
                Image(systemName: "timer")
                Text(timerInterval: Date()...max(endDate, Date().addingTimeInterval(1)), countsDown: true)
                    .monospacedDigit()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(WidgetTheme.coral)
            .frame(minWidth: 100, alignment: .trailing)
        } else if let remaining = state.pausedRemainingSeconds {
            HStack(spacing: 4) {
                Image(systemName: "pause.fill")
                Text(Self.formattedTime(remaining))
                    .monospacedDigit()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(WidgetTheme.textMuted)
            .frame(minWidth: 100, alignment: .trailing)
        }
    }

    private static func formattedTime(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

/// "Rate it" (Link — opens the app to the feedback flow) / "Not now"
/// (Button(intent:) — ends the Activity without opening the app) row shown
/// once cooking finishes. Shared by the Lock Screen and Dynamic Island
/// expanded presentations, matching how ActionRow above is shared for the
/// in-progress state.
private struct FeedbackPromptActionRow: View {
    let sessionID: UUID
    let mutedTint: Color
    let accentTint: Color

    var body: some View {
        HStack(spacing: 8) {
            Button(intent: DismissFeedbackPromptIntent()) {
                Text("Not now").lineLimit(1)
            }
            .buttonStyle(FilledButtonStyle(fill: mutedTint))

            Link(destination: feedbackURL(sessionID: sessionID)) {
                Text("⭐ Rate it").lineLimit(1)
            }
            .buttonStyle(FilledButtonStyle(fill: accentTint))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .font(.caption.weight(.semibold))
    }
}

private struct FinishedLockScreenView: View {
    let attributes: CookingActivityAttributes

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("🎉 \(attributes.recipeTitle) is ready!")
                .font(.title3.weight(.bold))
                .foregroundStyle(WidgetTheme.textDark)
                .lineLimit(2)

            Text("How did it turn out?")
                .font(.subheadline)
                .foregroundStyle(WidgetTheme.textDark.opacity(0.8))

            FeedbackPromptActionRow(
                sessionID: attributes.sessionID,
                mutedTint: WidgetTheme.textMuted,
                accentTint: WidgetTheme.coral
            )
            .padding(.top, 2)
        }
        .padding(16)
        .activityBackgroundTint(WidgetTheme.creamBackground)
        .activitySystemActionForegroundColor(WidgetTheme.textDark)
    }
}

private struct FinishedIslandView: View {
    let attributes: CookingActivityAttributes

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("🎉 \(attributes.recipeTitle) is ready!")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(WidgetTheme.islandTextPrimary)
                .lineLimit(2)

            Text("How did it turn out?")
                .font(.caption2)
                .foregroundStyle(WidgetTheme.islandTextMuted)

            FeedbackPromptActionRow(
                sessionID: attributes.sessionID,
                mutedTint: WidgetTheme.islandTextMuted,
                accentTint: WidgetTheme.coral
            )
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
