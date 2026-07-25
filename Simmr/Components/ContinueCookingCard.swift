//
//  ContinueCookingCard.swift
//  Simmr
//

import SwiftUI

struct ContinueCookingCard: View {
    let session: CookingSession
    let onTap: () -> Void

    private var stepNumber: Int { session.currentStepIndex + 1 }
    private var totalSteps: Int { session.recipe.steps.count }
    private var progress: Double { Double(stepNumber) / Double(max(totalSteps, 1)) }

    private var timerRemainingLabel: String? {
        guard session.isTimerRunning, let timerEndDate = session.timerEndDate else { return nil }
        let remainingSeconds = timerEndDate.timeIntervalSinceNow
        guard remainingSeconds > 0 else { return nil }
        let minutes = max(1, Int(ceil(remainingSeconds / 60)))
        return "⏱ \(minutes) min remaining"
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(Theme.Colors.coral)
                    Text("Continue Cooking")
                        .font(Theme.Typography.footnote.weight(.semibold))
                        .foregroundStyle(Theme.Colors.coral)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textMuted)
                }

                Text(session.recipe.title)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textDark)
                    .lineLimit(1)

                StepProgressBar(progress: progress)

                HStack(spacing: Theme.Spacing.xs) {
                    Text("Step \(stepNumber) of \(totalSteps)")
                    if let timerRemainingLabel {
                        Text("·")
                        Text(timerRemainingLabel)
                    }
                }
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textMuted)
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .cardStyle()
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.md) {
        ContinueCookingCard(
            session: CookingSession(
                id: UUID(),
                recipe: .preview,
                currentStepIndex: 1,
                completedStepIndices: [0],
                servings: 4,
                timerEndDate: nil,
                timerRemainingSeconds: 0,
                isTimerRunning: false,
                isTimerComplete: false,
                timerTotalOverride: nil,
                startedAt: Date(),
                updatedAt: Date(),
                status: .active
            ),
            onTap: {}
        )
        ContinueCookingCard(
            session: CookingSession(
                id: UUID(),
                recipe: .preview,
                currentStepIndex: 3,
                completedStepIndices: [0, 1, 2],
                servings: 4,
                timerEndDate: Date().addingTimeInterval(18 * 60),
                timerRemainingSeconds: 18 * 60,
                isTimerRunning: true,
                isTimerComplete: false,
                timerTotalOverride: nil,
                startedAt: Date(),
                updatedAt: Date(),
                status: .active
            ),
            onTap: {}
        )
    }
    .padding()
    .background(Theme.Colors.creamBackground)
}
