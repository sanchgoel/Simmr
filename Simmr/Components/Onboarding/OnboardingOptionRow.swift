//
//  OnboardingOptionRow.swift
//  Simmr
//
//  Shared row for single-select and multi-select onboarding questions.
//

import SwiftUI

enum OnboardingSelectionIndicatorStyle {
    /// Single-select: no indicator when unselected, checkmark when selected.
    case checkmarkOnly
    /// Multi-select: empty circle when unselected, filled checkmark when selected.
    case circle
}

struct OnboardingOptionRow: View {
    let label: String
    let isSelected: Bool
    let isDisabled: Bool
    var indicatorStyle: OnboardingSelectionIndicatorStyle = .circle
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.sm) {
                Text(label)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textDark)
                    .frame(maxWidth: .infinity, alignment: .leading)

                indicator
            }
            .padding(Theme.Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .selectionTint(isSelected: isSelected)
        .opacity(isDisabled ? 0.4 : 1)
        .disabled(isDisabled)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    @ViewBuilder
    private var indicator: some View {
        switch indicatorStyle {
        case .checkmarkOnly:
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Theme.Colors.coral)
            }
        case .circle:
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(isSelected ? Theme.Colors.coral : Theme.Colors.border)
        }
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.xs) {
        OnboardingOptionRow(label: "Every day", isSelected: true, isDisabled: false, indicatorStyle: .checkmarkOnly) {}
        OnboardingOptionRow(label: "Rarely", isSelected: false, isDisabled: false, indicatorStyle: .checkmarkOnly) {}
        OnboardingOptionRow(label: "Weekends", isSelected: false, isDisabled: true, indicatorStyle: .checkmarkOnly) {}
        OnboardingOptionRow(label: "Me", isSelected: true, isDisabled: false, indicatorStyle: .circle) {}
        OnboardingOptionRow(label: "Partner", isSelected: false, isDisabled: false, indicatorStyle: .circle) {}
    }
    .padding()
    .background(Theme.Colors.creamBackground)
}
