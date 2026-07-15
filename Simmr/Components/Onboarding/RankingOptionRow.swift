//
//  RankingOptionRow.swift
//  Simmr
//
//  Row for ranking questions — tapping assigns the next open rank; tapping
//  an already-ranked row removes it and shifts the remaining ranks down.
//

import SwiftUI

struct RankingOptionRow: View {
    let label: String
    let rank: Int?
    let isDisabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.sm) {
                rankBadge
                Text(label)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textDark)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(Theme.Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .selectionTint(isSelected: rank != nil)
        .opacity(isDisabled ? 0.4 : 1)
        .disabled(isDisabled)
        .animation(.easeInOut(duration: 0.15), value: rank)
    }

    private var rankBadge: some View {
        ZStack {
            Circle()
                .fill(rank != nil ? Theme.Colors.coral : Theme.Colors.creamBackground)
                .overlay(
                    Circle().strokeBorder(Theme.Colors.border, lineWidth: rank != nil ? 0 : Theme.Stroke.regular)
                )
            if let rank {
                Text("\(rank)")
                    .font(Theme.Typography.footnote.weight(.bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 26, height: 26)
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.xs) {
        RankingOptionRow(label: "Decide what to cook", rank: 1, isDisabled: false) {}
        RankingOptionRow(label: "Step-by-step cooking", rank: 2, isDisabled: false) {}
        RankingOptionRow(label: "Grocery lists", rank: nil, isDisabled: false) {}
        RankingOptionRow(label: "Meal planning", rank: nil, isDisabled: true) {}
    }
    .padding()
    .background(Theme.Colors.creamBackground)
}
