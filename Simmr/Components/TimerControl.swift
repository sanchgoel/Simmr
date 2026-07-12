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
    let onStart: () -> Void
    let onPause: () -> Void
    let onReset: () -> Void

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

            HStack(spacing: Theme.Spacing.sm) {
                Button(isRunning ? "Pause" : "Start", action: isRunning ? onPause : onStart)
                    .buttonStyle(.primary)
                    .disabled(isComplete)

                Button("Reset", action: onReset)
                    .buttonStyle(.secondary)
            }
        }
    }

    private var formattedTime: String {
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    TimerControl(remaining: 95, progress: 0.4, isRunning: false, isComplete: false, onStart: {}, onPause: {}, onReset: {})
        .padding()
        .background(Theme.Colors.creamBackground)
}
