//
//  GroceryChecklistView.swift
//  Simmr
//

import SwiftUI

struct GroceryChecklistView: View {
    @ObservedObject var session: RecipeSession
    @Binding var path: [AppRoute]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Grocery Checklist")
                            .font(Theme.Typography.title)
                            .foregroundStyle(Theme.Colors.textDark)

                        progressLabel
                        progressBar
                    }

                    ForEach(session.ingredientSections) { section in
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            if let title = section.title {
                                Text(title)
                                    .font(Theme.Typography.headline)
                                    .foregroundStyle(Theme.Colors.textDark)
                            }
                            VStack(spacing: Theme.Spacing.xs) {
                                ForEach(section.ingredients) { ingredient in
                                    IngredientRow(ingredient: ingredient) {
                                        session.toggleChecked(ingredient)
                                    }
                                }
                            }
                        }
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
        .navigationTitle("Checklist")
        .navigationBarTitleDisplayMode(.inline)
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
        GroceryChecklistView(session: RecipeSession(recipe: .preview), path: .constant([]))
    }
}
