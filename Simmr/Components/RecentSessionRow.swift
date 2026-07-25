//
//  RecentSessionRow.swift
//  Simmr
//

import SwiftUI

struct RecentSessionRow: View {
    let session: CookingSession
    let onTap: () -> Void

    private var statusLabel: String {
        switch session.status {
        case .active, .paused: return "In Progress"
        case .completed: return "Completed"
        case .notStarted: return "Not Started"
        }
    }

    private var statusColor: Color {
        switch session.status {
        case .active, .paused: return Theme.Colors.coral
        case .completed, .notStarted: return Theme.Colors.textMuted
        }
    }

    private var statusIcon: String {
        switch session.status {
        case .active, .paused: return "flame.fill"
        case .completed: return "checkmark.circle.fill"
        case .notStarted: return "bookmark.fill"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: statusIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(statusColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(session.recipe.title)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textDark)
                        .lineLimit(1)
                    Text("\(statusLabel) · \(session.updatedAt.relativeDayLabel)")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textMuted)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textMuted)
            }
            .padding(Theme.Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Theme.Colors.creamCard)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
    }
}

private extension Date {
    /// "Today"/"Yesterday"/"N days ago" — calendar-day-based rather than
    /// exact-duration ("3 hours ago"), matching how a recipe history reads
    /// most naturally.
    var relativeDayLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) { return "Today" }
        if calendar.isDateInYesterday(self) { return "Yesterday" }
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: self),
            to: calendar.startOfDay(for: Date())
        ).day ?? 0
        return "\(days) days ago"
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.xs) {
        RecentSessionRow(
            session: CookingSession(
                id: UUID(),
                recipe: .preview,
                currentStepIndex: 0,
                completedStepIndices: [],
                servings: 4,
                timerEndDate: nil,
                timerRemainingSeconds: 0,
                isTimerRunning: false,
                isTimerComplete: false,
                timerTotalOverride: nil,
                startedAt: Date(),
                updatedAt: Date(),
                status: .notStarted
            ),
            onTap: {}
        )
        RecentSessionRow(
            session: CookingSession(
                id: UUID(),
                recipe: .preview,
                currentStepIndex: 2,
                completedStepIndices: [0, 1],
                servings: 4,
                timerEndDate: nil,
                timerRemainingSeconds: 0,
                isTimerRunning: false,
                isTimerComplete: false,
                timerTotalOverride: nil,
                startedAt: Date(),
                updatedAt: Date().addingTimeInterval(-3600),
                status: .paused
            ),
            onTap: {}
        )
        RecentSessionRow(
            session: CookingSession(
                id: UUID(),
                recipe: .preview,
                currentStepIndex: 4,
                completedStepIndices: [0, 1, 2, 3, 4],
                servings: 4,
                timerEndDate: nil,
                timerRemainingSeconds: 0,
                isTimerRunning: false,
                isTimerComplete: false,
                timerTotalOverride: nil,
                startedAt: Date().addingTimeInterval(-172_800),
                updatedAt: Date().addingTimeInterval(-172_000),
                status: .completed
            ),
            onTap: {}
        )
    }
    .padding()
    .background(Theme.Colors.creamBackground)
}
