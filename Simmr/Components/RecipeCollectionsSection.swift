//
//  RecipeCollectionsSection.swift
//  Simmr
//
//  Curated dashboard recipes with a compact, multi-select filter sheet.
//

import SwiftUI

struct RecipeCollectionsSection: View {
    @ObservedObject var controller: RecipeCollectionsController
    let onSelectRecipe: (Recipe) -> Void

    @State private var isShowingFilters = false

    var body: some View {
        if shouldShowSection {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                sectionHeader

                if controller.isLoading && controller.collections.isEmpty {
                    loadingCard
                } else if let errorMessage = controller.errorMessage,
                          controller.collections.isEmpty {
                    errorCard(errorMessage)
                } else if controller.visibleCollections.isEmpty {
                    noMatchesCard
                } else {
                    ForEach(controller.visibleCollections) { collection in
                        collectionSection(collection)
                    }
                }
            }
            .sheet(isPresented: $isShowingFilters) {
                RecipeFiltersSheet(
                    options: controller.filterOptions,
                    selection: $controller.selectedFilters
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Theme.Colors.creamBackground)
            }
        }
    }

    private var shouldShowSection: Bool {
        controller.isLoading ||
        controller.errorMessage != nil ||
        !controller.collections.isEmpty
    }

    private var sectionHeader: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Text("Explore Recipes")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.textDark)

            Spacer()

            Button {
                isShowingFilters = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "line.3.horizontal.decrease")
                    Text(filterButtonTitle)
                }
                .font(Theme.Typography.caption)
                .foregroundStyle(
                    controller.selectedFilters.isEmpty ?
                    Theme.Colors.textDark :
                    Theme.Colors.coral
                )
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, 7)
                .background(
                    controller.selectedFilters.isEmpty ?
                    Theme.Colors.creamCard :
                    Theme.Colors.tint
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            controller.selectedFilters.isEmpty ?
                            Theme.Colors.border :
                            Theme.Colors.coral,
                            lineWidth: Theme.Stroke.hairline
                        )
                )
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(controller.filterOptions.isEmpty)
        }
    }

    private var filterButtonTitle: String {
        let count = controller.selectedFilters.count
        return count == 0 ? "Filter" : "Filter · \(count)"
    }

    private var loadingCard: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ProgressView()
                .tint(Theme.Colors.coral)
            Text("Loading recipe collections…")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .cardStyle()
    }

    private func errorCard(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(message)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.textMuted)

            Button("Try Again") {
                Task { await controller.refresh() }
            }
            .font(Theme.Typography.subheadline.weight(.semibold))
            .foregroundStyle(Theme.Colors.coral)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .cardStyle()
    }

    private var noMatchesCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("No recipes match those filters.")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.textMuted)

            Button("Clear Filters") {
                controller.clearFilters()
            }
            .font(Theme.Typography.subheadline.weight(.semibold))
            .foregroundStyle(Theme.Colors.coral)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .cardStyle()
    }

    private func collectionSection(_ collection: RecipeCollection) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(collection.name)
                    .font(Theme.Typography.title3)
                    .foregroundStyle(Theme.Colors.textDark)

                if !collection.description.isEmpty {
                    Text(collection.description)
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.textMuted)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: Theme.Spacing.sm) {
                    ForEach(collection.recipes) { libraryRecipe in
                        recipeCard(libraryRecipe)
                    }
                }
            }
        }
    }

    private func recipeCard(_ libraryRecipe: LibraryRecipe) -> some View {
        Button {
            onSelectRecipe(libraryRecipe.recipe)
        } label: {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text(libraryRecipe.recipe.title)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textDark)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                if let description = libraryRecipe.recipe.description,
                   !description.isEmpty {
                    Text(description)
                        .font(Theme.Typography.footnote)
                        .foregroundStyle(Theme.Colors.textMuted)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                recipeMetadata(libraryRecipe.recipe)

                HStack {
                    if let cuisine = libraryRecipe.recipe.cuisine,
                       !cuisine.isEmpty {
                        tag(cuisine)
                    }
                    if let mealType = libraryRecipe.recipe.mealType.first {
                        tag(mealType)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.Colors.coral)
                }
            }
            .padding(Theme.Spacing.md)
            .frame(width: 252, height: 184, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .cardStyle()
        .accessibilityHint("Opens the recipe")
    }

    private func recipeMetadata(_ recipe: Recipe) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            if let totalMinutes = totalMinutes(for: recipe) {
                Label("\(totalMinutes) min", systemImage: "clock")
            }
            Label("\(recipe.servings)", systemImage: "person.2")
        }
        .font(Theme.Typography.caption2)
        .foregroundStyle(Theme.Colors.textMuted)
    }

    private func totalMinutes(for recipe: Recipe) -> Int? {
        let values = [recipe.prepTimeMinutes, recipe.cookTimeMinutes].compactMap { $0 }
        return values.isEmpty ? nil : values.reduce(0, +)
    }

    private func tag(_ text: String) -> some View {
        Text(text)
            .font(Theme.Typography.caption2)
            .foregroundStyle(Theme.Colors.coral)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Theme.Colors.tint)
            .clipShape(Capsule())
    }
}

private struct RecipeFiltersSheet: View {
    let options: RecipeFilterOptions
    @Binding var selection: RecipeFilterSelection

    @Environment(\.dismiss) private var dismiss
    @State private var draftSelection: RecipeFilterSelection
    @State private var selectedCategory: FilterCategory = .cuisine

    init(
        options: RecipeFilterOptions,
        selection: Binding<RecipeFilterSelection>
    ) {
        self.options = options
        _selection = selection
        _draftSelection = State(initialValue: selection.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    categoryRail

                    Divider()
                        .overlay(Theme.Colors.border)

                    optionPane
                }

                Divider()
                    .overlay(Theme.Colors.border)

                applyButton
            }
            .background(Theme.Colors.creamBackground.ignoresSafeArea())
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Clear All") {
                        draftSelection.clear()
                    }
                    .disabled(draftSelection.isEmpty)
                }
            }
            .onAppear {
                if !availableCategories.contains(selectedCategory),
                   let firstCategory = availableCategories.first {
                    selectedCategory = firstCategory
                }
            }
        }
    }

    private var categoryRail: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(availableCategories) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        HStack {
                            Text(category.title)
                                .font(Theme.Typography.subheadline)
                                .lineLimit(1)

                            Spacer()
                        }
                        .foregroundStyle(
                            selectedCategory == category ?
                            Theme.Colors.coral :
                            Theme.Colors.textDark
                        )
                        .padding(.horizontal, Theme.Spacing.sm)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(
                            selectedCategory == category ?
                            Theme.Colors.creamBackground :
                            Theme.Colors.creamCard
                        )
                        .overlay(alignment: .leading) {
                            if selectedCategory == category {
                                Rectangle()
                                    .fill(Theme.Colors.coral)
                                    .frame(width: 3)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(width: 132)
        .background(Theme.Colors.creamCard)
    }

    private var optionPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(selectedCategory.title)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textDark)

                Spacer()

                if selectionCount(for: selectedCategory) > 0 {
                    Button("Clear") {
                        selectedValues(for: selectedCategory).wrappedValue.removeAll()
                    }
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.coral)
                }
            }
            .padding(Theme.Spacing.md)

            Divider()
                .overlay(Theme.Colors.border)

            ScrollView {
                LazyVStack(spacing: Theme.Spacing.xs) {
                    ForEach(optionValues(for: selectedCategory), id: \.self) { option in
                        optionRow(option, category: selectedCategory)
                    }
                }
                .padding(Theme.Spacing.md)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func optionRow(
        _ option: String,
        category: FilterCategory
    ) -> some View {
        let selectedValues = selectedValues(for: category)
        let isSelected = selectedValues.wrappedValue.contains(option)

        return Button {
            var updatedValues = selectedValues.wrappedValue
            if isSelected {
                updatedValues.remove(option)
            } else {
                updatedValues.insert(option)
            }
            selectedValues.wrappedValue = updatedValues
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(
                        isSelected ?
                        Theme.Colors.coral :
                        Theme.Colors.border
                    )

                Text(optionLabel(option, category: category))
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.textDark)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.sm)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(isSelected ? Theme.Colors.tint : Theme.Colors.creamCard)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .strokeBorder(
                        isSelected ? Theme.Colors.coral : Theme.Colors.border,
                        lineWidth: Theme.Stroke.hairline
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var applyButton: some View {
        Button {
            selection = draftSelection
            dismiss()
        } label: {
            Text(applyButtonTitle)
        }
        .buttonStyle(.primary)
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.Colors.creamBackground)
    }

    private var applyButtonTitle: String {
        let count = draftSelection.count
        return count == 0 ? "Show All Recipes" : "Apply \(count) Filter\(count == 1 ? "" : "s")"
    }

    private var availableCategories: [FilterCategory] {
        FilterCategory.allCases.filter { !optionValues(for: $0).isEmpty }
    }

    private func optionValues(for category: FilterCategory) -> [String] {
        switch category {
        case .cuisine: options.cuisines
        case .meal: options.mealTypes
        case .dietary: options.dietaryTags
        case .difficulty: options.difficulties
        case .totalTime: options.totalTimes
        case .calories: options.calorieRanges
        case .servings: options.servingSizes
        }
    }

    private func selectedValues(
        for category: FilterCategory
    ) -> Binding<Set<String>> {
        switch category {
        case .cuisine: $draftSelection.cuisines
        case .meal: $draftSelection.mealTypes
        case .dietary: $draftSelection.dietaryTags
        case .difficulty: $draftSelection.difficulties
        case .totalTime: $draftSelection.totalTimes
        case .calories: $draftSelection.calorieRanges
        case .servings: $draftSelection.servingSizes
        }
    }

    private func selectionCount(for category: FilterCategory) -> Int {
        selectedValues(for: category).wrappedValue.count
    }

    private func optionLabel(
        _ option: String,
        category: FilterCategory
    ) -> String {
        switch category {
        case .totalTime, .calories, .servings:
            option
        default:
            option.capitalized
        }
    }

    private enum FilterCategory: String, CaseIterable, Identifiable {
        case cuisine
        case meal
        case dietary
        case difficulty
        case totalTime
        case calories
        case servings

        var id: String { rawValue }

        var title: String {
            switch self {
            case .cuisine: "Cuisine"
            case .meal: "Meal"
            case .dietary: "Dietary"
            case .difficulty: "Difficulty"
            case .totalTime: "Total Time"
            case .calories: "Calories"
            case .servings: "Servings"
            }
        }

    }
}
