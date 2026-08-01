//
//  CelebrationHeaderView.swift
//  Simmr
//
//  Reusable title+subtitle header for every screen of the post-cooking
//  feedback flow — spec's copy embeds emoji directly in the title text
//  rather than as a separate glyph, so this is deliberately just two
//  centered text blocks, not an icon+text layout.
//

import SwiftUI

struct CelebrationHeaderView: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(title)
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.Colors.textDark)
                .multilineTextAlignment(.center)
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.textMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    CelebrationHeaderView(title: "You nailed it! 🎉", subtitle: "That dish deserves its moment.")
        .padding()
        .background(Theme.Colors.creamBackground)
}
