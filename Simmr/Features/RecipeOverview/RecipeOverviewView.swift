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
                header

                ServingsStepper(servings: $session.servings)
                    .padding(Theme.Spacing.md)
                    .cardStyle()

                ForEach(session.ingredientSections) { section in
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text(section.title ?? "Ingredients")
                            .font(Theme.Typography.title3)
                            .foregroundStyle(Theme.Colors.textDark)

                        VStack(spacing: Theme.Spacing.xs) {
                            ForEach(section.ingredients) { ingredient in
                                HStack(spacing: Theme.Spacing.xxs) {
                                    Text(ingredient.name)
                                        .font(Theme.Typography.body)
                                        .foregroundStyle(Theme.Colors.textDark)
                                    if ingredient.optional {
                                        Text("optional")
                                            .font(Theme.Typography.caption2)
                                            .foregroundStyle(Theme.Colors.textMuted)
                                    }
                                    Spacer()
                                    if let quantityLabel = ingredient.quantityLabel {
                                        Text(quantityLabel)
                                            .font(Theme.Typography.subheadline)
                                            .foregroundStyle(Theme.Colors.textMuted)
                                            .contentTransition(.numericText())
                                    }
                                }
                                .padding(Theme.Spacing.sm)
                                .background(Theme.Colors.creamCard)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
                            }
                        }
                        .animation(.easeInOut(duration: 0.2), value: session.servings)
                    }
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

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            Text(session.title)
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.Colors.textDark)

            if let description = session.description {
                Text(description)
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.textMuted)
            }

            HStack(spacing: Theme.Spacing.sm) {
                Label("\(session.baseServings) servings", systemImage: "person.2")
                if let prepTime = session.prepTimeMinutes {
                    Label("\(prepTime) min prep", systemImage: "timer")
                }
                if let cookTime = session.cookTimeMinutes {
                    Label("\(cookTime) min cook", systemImage: "flame")
                }
            }
            .font(Theme.Typography.caption)
            .foregroundStyle(Theme.Colors.textMuted)
            .padding(.top, Theme.Spacing.xxs)
        }
    }
}

#Preview {
    NavigationStack {
        RecipeOverviewView(session: RecipeSession(recipe: .preview), path: .constant([]))
    }
}
