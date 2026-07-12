//
//  RecipeOverviewView.swift
//  Simmr
//

import SwiftUI

struct RecipeOverviewView: View {
    @ObservedObject var session: RecipeSession
    @Binding var path: [AppRoute]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text(session.title)
                        .font(Theme.Typography.title)
                        .foregroundStyle(Theme.Colors.textDark)
                    Text("Default serving size: \(session.baseServings)")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.textMuted)
                }

                ServingsStepper(servings: $session.servings)
                    .padding(Theme.Spacing.md)
                    .cardStyle()

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Ingredients")
                        .font(Theme.Typography.title3)
                        .foregroundStyle(Theme.Colors.textDark)

                    VStack(spacing: Theme.Spacing.xs) {
                        ForEach(session.ingredients) { ingredient in
                            HStack {
                                Text(ingredient.name)
                                    .font(Theme.Typography.body)
                                    .foregroundStyle(Theme.Colors.textDark)
                                Spacer()
                                Text("\(QuantityFormatter.format(ingredient.quantity)) \(ingredient.unit)")
                                    .font(Theme.Typography.subheadline)
                                    .foregroundStyle(Theme.Colors.textMuted)
                                    .contentTransition(.numericText())
                            }
                            .padding(Theme.Spacing.sm)
                            .background(Theme.Colors.creamCard)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: session.servings)
                }

                Button("View Grocery Checklist") {
                    path.append(.grocery)
                }
                .buttonStyle(.primary)
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Colors.creamBackground.ignoresSafeArea())
        .navigationTitle("Recipe")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        RecipeOverviewView(session: RecipeSession(recipe: .preview), path: .constant([]))
    }
}
