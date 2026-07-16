//
//  TimerControl.swift
//  Simmr
//

import SwiftUI

struct TimerControl: View {
    let remaining: Int
    let progress: Double
    let isRunning: Bool
    let isComplete: Bool
    let totalMinutes: Int
    let canDecreaseMinute: Bool
    let onStart: () -> Void
    let onPause: () -> Void
    let onReset: () -> Void
    let onIncrementMinute: () -> Void
    let onDecrementMinute: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .stroke(Theme.Colors.border, lineWidth: 8)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        isComplete ? Theme.Colors.amber : Theme.Colors.coral,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)

                VStack(spacing: Theme.Spacing.xxs) {
                    if isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Theme.Colors.amber)
                        Text("Done")
                            .font(Theme.Typography.headline)
                            .foregroundStyle(Theme.Colors.textDark)
                    } else {
                        Text(formattedTime)
                            .font(Theme.Typography.timerDisplay)
                            .foregroundStyle(Theme.Colors.textDark)
                            .contentTransition(.numericText(countsDown: true))
                            .animation(.snappy, value: remaining)
                    }
                }
            }
            .frame(width: 160, height: 160)

            HStack(spacing: Theme.Spacing.md) {
                Text("Timer")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textDark)

                Spacer()

                HStack(spacing: Theme.Spacing.sm) {
                    stepperButton(systemImage: "minus", action: onDecrementMinute, isEnabled: canDecreaseMinute)

                    Text("\(totalMinutes) min")
                        .font(Theme.Typography.title3)
                        .foregroundStyle(Theme.Colors.textDark)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .frame(minWidth: 64)
                        .contentTransition(.numericText())
                        .animation(.snappy, value: totalMinutes)

                    stepperButton(systemImage: "plus", action: onIncrementMinute, isEnabled: true)
                }
            }

            HStack(spacing: Theme.Spacing.sm) {
                Button(isRunning ? "Pause" : "Start", action: isRunning ? onPause : onStart)
                    .buttonStyle(.primary)
                    .disabled(isComplete)

                Button("Reset", action: onReset)
                    .buttonStyle(.secondary)
            }
        }
    }

    private func stepperButton(systemImage: String, action: @escaping () -> Void, isEnabled: Bool) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isEnabled ? Theme.Colors.textDark : Theme.Colors.textMuted)
                .frame(width: 32, height: 32)
                .background(Theme.Colors.creamCard)
                .overlay(
                    Circle().strokeBorder(Theme.Colors.border, lineWidth: Theme.Stroke.hairline)
                )
                .clipShape(Circle())
        }
        .disabled(!isEnabled)
    }

    private var formattedTime: String {
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    TimerControl(
        remaining: 95,
        progress: 0.4,
        isRunning: false,
        isComplete: false,
        totalMinutes: 3,
        canDecreaseMinute: false,
        onStart: {},
        onPause: {},
        onReset: {},
        onIncrementMinute: {},
        onDecrementMinute: {}
    )
    .padding()
    .background(Theme.Colors.creamBackground)
}
