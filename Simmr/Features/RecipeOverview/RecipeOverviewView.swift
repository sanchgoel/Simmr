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
    /// Staged by whoever pushed this screen (Home) so "Start Cooking" can
    /// forward it straight onto `.cooking` without reading back through any
    /// sibling state — see `AppRoute` for why routes carry their own data.
    let pendingCookingSession: CookingSession?
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
                path.append(.cooking(session, pendingCookingSession))
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

            FlowLayout(spacing: Theme.Spacing.xs) {
                metaPill(icon: "person.2", text: "\(session.baseServings) servings")
                if let prepTime = session.prepTimeMinutes {
                    metaPill(icon: "timer", text: "\(prepTime) min prep")
                }
                if let cookTime = session.cookTimeMinutes {
                    metaPill(icon: "flame", text: "\(cookTime) min cook")
                }
                if let calories = session.caloriesPerServing {
                    metaPill(icon: "bolt.fill", text: "\(calories) kcal")
                }
            }
            .padding(.top, Theme.Spacing.xs)
        }
    }

    private func metaPill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.Colors.coral)
            Text(text)
                .font(Theme.Typography.caption.weight(.medium))
                .foregroundStyle(Theme.Colors.textDark)
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, 6)
        .background(Theme.Colors.tint)
        .clipShape(Capsule())
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
        RecipeOverviewView(session: RecipeSession(recipe: .preview), pendingCookingSession: nil, path: .constant([]))
    }
}
