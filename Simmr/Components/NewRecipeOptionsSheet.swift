//
//  NewRecipeOptionsSheet.swift
//  Simmr
//
//  A custom-styled bottom sheet for the four recipe-creation methods,
//  presented from HomeView's pinned "New Recipe" CTA. Built as our own
//  view rather than a system confirmationDialog/actionSheet so it always
//  reads as a clean, on-brand bottom sheet regardless of how a given iOS
//  version happens to render those system components.
//

import SwiftUI

enum RecipeCreationOption {
    case camera
    case photos
    case paste
    case dishName
}

struct NewRecipeOptionsSheet: View {
    var onSelect: (RecipeCreationOption) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("New Recipe")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.textDark)

            VStack(spacing: Theme.Spacing.xs) {
                optionRow(emoji: "📷", title: "Scan with Camera", option: .camera)
                optionRow(emoji: "🖼", title: "Import Photos", option: .photos)
                optionRow(emoji: "📋", title: "Paste Recipe", option: .paste)
                optionRow(emoji: "🍳", title: "Type Dish Name", option: .dishName)
            }
        }
        .padding(Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.sm)
    }

    private func optionRow(emoji: String, title: String, option: RecipeCreationOption) -> some View {
        Button {
            onSelect(option)
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Text(emoji)
                    .font(.system(size: 22))
                Text(title)
                    .font(Theme.Typography.body.weight(.semibold))
                    .foregroundStyle(Theme.Colors.textDark)
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

#Preview {
    NewRecipeOptionsSheet { _ in }
}
