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

                Text(ingredient.name)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textDark)
                    .strikethrough(ingredient.checked, color: Theme.Colors.textMuted)
                    .opacity(ingredient.checked ? 0.6 : 1)

                Spacer()

                Text("\(QuantityFormatter.format(ingredient.quantity)) \(ingredient.unit)")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.textMuted)
            }
            .padding(Theme.Spacing.sm)
        }
        .buttonStyle(.plain)
        .background(ingredient.checked ? Theme.Colors.tint : Theme.Colors.creamCard)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        .animation(.easeInOut(duration: 0.15), value: ingredient.checked)
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.xs) {
        IngredientRow(ingredient: Ingredient(name: "Spaghetti", quantity: 12, unit: "oz", checked: false)) {}
        IngredientRow(ingredient: Ingredient(name: "Butter", quantity: 3, unit: "tbsp", checked: true)) {}
    }
    .padding()
    .background(Theme.Colors.creamBackground)
}
