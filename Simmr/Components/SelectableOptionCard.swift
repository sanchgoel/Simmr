//
//  SelectableOptionCard.swift
//  Simmr
//
//  Large single-select card with no chevron — unlike LargeOptionCard, this
//  doesn't drill into another screen, it just marks a selection (checkmark)
//  so the detail screen can still show a text field + explicit Submit
//  afterward.
//

import SwiftUI

struct SelectableOptionCard: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textDark)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: Theme.Spacing.sm)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.Colors.coral)
                }
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .selectionTint(isSelected: isSelected)
    }
}

#Preview {
    VStack(spacing: 12) {
        SelectableOptionCard(title: "Didn't taste as expected", isSelected: true, action: {})
        SelectableOptionCard(title: "Ingredient quantities felt off", isSelected: false, action: {})
    }
    .padding()
    .background(Theme.Colors.creamBackground)
}
