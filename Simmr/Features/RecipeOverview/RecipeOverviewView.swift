//
//  RecipeOverviewView.swift
//  Simmr
//
//  Single recipe screen: adjust servings, check off ingredients you have on
//  hand, then start cooking. Combines what used to be a separate overview
//  and grocery checklist screen since they showed the same ingredient list.
//

import SwiftUI

struct RecipeOverviewView: View {
    @ObservedObject var session: RecipeSession
    @Binding var path: [AppRoute]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    header

                    if let optimizationSummary = session.optimizationSummary {
                        optimizationCallout(optimizationSummary)
                    }

                    ServingsStepper(servings: $session.servings)
                        .padding(Theme.Spacing.md)
                        .cardStyle()

                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        progressLabel
                        progressBar
                    }

                    ForEach(session.ingredientSections) { section in
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Text(section.title ?? "Ingredients")
                                .font(Theme.Typography.title3)
                                .foregroundStyle(Theme.Colors.textDark)

                            VStack(spacing: Theme.Spacing.xs) {
                                ForEach(section.ingredients) { ingredient in
                                    IngredientRow(ingredient: ingredient) {
                                        session.toggleChecked(ingredient)
                                    }
                                }
                            }
                        }
                        .animation(.easeInOut(duration: 0.2), value: session.servings)
                    }
                }
                .padding(Theme.Spacing.lg)
            }

            Divider()
                .overlay(Theme.Colors.border)

            Button("Start Cooking") {
                path.append(.cooking)
            }
            .buttonStyle(.primary)
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

            FlowLayout(spacing: Theme.Spacing.sm) {
                Label("\(session.baseServings) servings", systemImage: "person.2")
                if let prepTime = session.prepTimeMinutes {
                    Label("\(prepTime) min prep", systemImage: "timer")
                }
                if let cookTime = session.cookTimeMinutes {
                    Label("\(cookTime) min cook", systemImage: "flame")
                }
                if let calories = session.caloriesPerServing {
                    Label("\(calories) kcal", systemImage: "bolt.fill")
                }
            }
            .font(Theme.Typography.caption)
            .foregroundStyle(Theme.Colors.textMuted)
            .padding(.top, Theme.Spacing.xxs)
        }
    }

    private func optimizationCallout(_ summary: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.xs) {
            Image(systemName: "sparkles")
                .foregroundStyle(Theme.Colors.coral)
            Text(summary)
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Colors.textMuted)
        }
        .padding(Theme.Spacing.sm)
        .background(Theme.Colors.tint)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
    }

    private var progressLabel: some View {
        Text("\(session.checkedCount) of \(session.totalCount) ingredients available")
            .font(Theme.Typography.subheadline)
            .foregroundStyle(Theme.Colors.textMuted)
            .contentTransition(.numericText())
            .animation(.easeInOut(duration: 0.15), value: session.checkedCount)
    }

    private var progressBar: some View {
        StepProgressBar(progress: session.totalCount == 0 ? 0 : Double(session.checkedCount) / Double(session.totalCount))
    }
}

#Preview {
    NavigationStack {
        RecipeOverviewView(session: RecipeSession(recipe: .preview), path: .constant([]))
    }
}
