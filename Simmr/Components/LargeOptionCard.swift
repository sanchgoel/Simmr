//
//  LargeOptionCard.swift
//  Simmr
//
//  Reusable large tappable card for single-select drill-down screens —
//  the chevron affordance is deliberate, matching the "feels like Settings
//  or Health" ask: tapping immediately advances, no separate Continue step.
//

import SwiftUI

struct LargeOptionCard: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textDark)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: Theme.Spacing.sm)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textMuted)
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .cardStyle()
    }
}

#Preview {
    VStack(spacing: 12) {
        LargeOptionCard(title: "🍳 The recipe", action: {})
        LargeOptionCard(title: "👨‍🍳 The cooking guidance", action: {})
    }
    .padding()
    .background(Theme.Colors.creamBackground)
}
