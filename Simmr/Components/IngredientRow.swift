//
//  IngredientRow.swift
//  Simmr
//

import SwiftUI

struct IngredientRow: View {
    let ingredient: Ingredient
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: ingredient.checked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(ingredient.checked ? Theme.Colors.coral : Theme.Colors.border)

                HStack(spacing: Theme.Spacing.xxs) {
                    Text(ingredient.name)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textDark)
                        .strikethrough(ingredient.checked, color: Theme.Colors.textMuted)
                        .opacity(ingredient.checked ? 0.6 : 1)

                    if ingredient.optional {
                        Text("optional")
                            .font(Theme.Typography.caption2)
                            .foregroundStyle(Theme.Colors.textMuted)
                            .padding(.horizontal, Theme.Spacing.xxs)
                            .padding(.vertical, 2)
                            .background(Theme.Colors.border.opacity(0.5))
                            .clipShape(Capsule())
                    }
                }

                Spacer()

                if let quantityLabel = ingredient.quantityLabel {
                    Text(quantityLabel)
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.textMuted)
                }
            }
            .padding(Theme.Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(ingredient.checked ? Theme.Colors.tint : Theme.Colors.creamCard)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        .animation(.easeInOut(duration: 0.15), value: ingredient.checked)
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.xs) {
        IngredientRow(ingredient: Ingredient(name: "Spaghetti", quantity: 12, unit: "oz")) {}
        IngredientRow(ingredient: Ingredient(name: "Butter", quantity: 3, unit: "tbsp", checked: true)) {}
        IngredientRow(ingredient: Ingredient(name: "Salt", optional: false)) {}
        IngredientRow(ingredient: Ingredient(name: "Fresh cilantro, chopped", quantity: 2, unit: "tbsp", optional: true)) {}
    }
    .padding()
    .background(Theme.Colors.creamBackground)
}
