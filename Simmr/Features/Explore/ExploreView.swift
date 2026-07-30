//
//  ExploreView.swift
//  Simmr
//
//  Dedicated browsing destination for curated recipe collections.
//

import SwiftUI

struct ExploreView: View {
    @StateObject private var controller = RecipeCollectionsController()
    @State private var path: [AppRoute] = []
    @State private var isShowingFilters = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                            Text("Explore")
                                .font(Theme.Typography.largeTitle)
                                .foregroundStyle(Theme.Colors.textDark)

                            Text("Discover recipes picked for every kind of craving.")
                                .font(Theme.Typography.subheadline)
                                .foregroundStyle(Theme.Colors.textMuted)
                        }

                        if !controller.filterOptions.isEmpty {
                            filterControls
                        }
                    }

                    RecipeCollectionsSection(
                        controller: controller,
                        showsFilterButton: false,
                        onSelectRecipe: openRecipe
                    )
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Theme.Colors.creamBackground.ignoresSafeArea())
            .task {
                await controller.loadIfNeeded()
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
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .overview(let session, let pendingCookingSession):
                    RecipeOverviewView(
                        session: session,
                        pendingCookingSession: pendingCookingSession,
                        path: $path
                    )
                    .toolbar(.hidden, for: .tabBar)

                case .cooking(let session, let existingCookingSession):
                    CookingModeView(
                        session: session,
                        path: $path,
                        existingCookingSession: existingCookingSession
                    )
                    .toolbar(.hidden, for: .tabBar)

                case .newRecipe:
                    EmptyView()
                }
            }
        }
    }

    private var filterControls: some View {
        HStack(spacing: 0) {
            quickFilters

            filterButtonSection
                .zIndex(1)
        }
    }

    private var quickFilters: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.xs) {
                    if controller.selectedFilters.isEmpty {
                        allFiltersPill
                    }

                    ForEach(selectedQuickFilters) { filter in
                        quickFilterPill(
                            title: filter.displayTitle,
                            isSelected: true
                        ) {
                            toggle(filter)
                        }
                        .id(filter.id)
                    }

                    if !controller.selectedFilters.isEmpty {
                        allFiltersPill
                    }

                    ForEach(unselectedQuickFilters) { filter in
                        quickFilterPill(
                            title: filter.displayTitle,
                            isSelected: false
                        ) {
                            toggle(filter)
                        }
                        .id(filter.id)
                    }
                }
            }
            .onChange(of: controller.selectedFilters) { _, selection in
                let targetID = selectedQuickFilters.first?.id ?? allFiltersID

                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        proxy.scrollTo(targetID, anchor: .leading)
                    }
                }
            }
        }
        .contentMargins(.leading, 1, for: .scrollContent)
        .contentMargins(.trailing, Theme.Spacing.sm, for: .scrollContent)
    }

    private var allFiltersPill: some View {
        quickFilterPill(
            title: "All",
            isSelected: controller.selectedFilters.isEmpty
        ) {
            withAnimation(.easeInOut(duration: 0.2)) {
                controller.clearFilters()
            }
        }
        .id(allFiltersID)
    }

    private var filterButtonSection: some View {
        RecipeFilterButton(
            selectedCount: controller.selectedFilters.count,
            isEnabled: !controller.filterOptions.isEmpty
        ) {
            isShowingFilters = true
        }
        .padding(.leading, Theme.Spacing.sm)
        .background(Theme.Colors.creamBackground)
        .overlay(alignment: .leading) {
            LinearGradient(
                colors: [
                    Color.clear,
                    Theme.Colors.textDark.opacity(0.06)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 20, height: 34)
            .clipShape(Capsule())
            .offset(x: -17)
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(Theme.Colors.creamBackground)
                    .frame(width: Theme.Stroke.hairline, height: 24)
                    .shadow(
                        color: Theme.Colors.textDark.opacity(0.06),
                        radius: 5,
                        x: -2,
                        y: 0
                    )
            }
            .allowsHitTesting(false)
        }
    }

    private func quickFilterPill(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? Color.white : Theme.Colors.textDark)
                .lineLimit(1)
                .padding(.horizontal, 14)
                .frame(height: 38)
                .background(isSelected ? Theme.Colors.coral : Theme.Colors.creamCard)
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isSelected ? Theme.Colors.coral : Theme.Colors.border,
                            lineWidth: Theme.Stroke.hairline
                        )
                )
                .clipShape(Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var quickFilterOptions: [ExploreQuickFilter] {
        [
            (category: ExploreQuickFilter.Category.totalTime, values: controller.filterOptions.totalTimes),
            (category: .meal, values: controller.filterOptions.mealTypes),
            (category: .dietary, values: controller.filterOptions.dietaryTags),
            (category: .difficulty, values: controller.filterOptions.difficulties),
            (category: .cuisine, values: controller.filterOptions.cuisines),
            (category: .calories, values: controller.filterOptions.calorieRanges),
            (category: .servings, values: controller.filterOptions.servingSizes)
        ]
        .flatMap { group in
            group.values.map {
                ExploreQuickFilter(category: group.category, value: $0)
            }
        }
    }

    private var selectedQuickFilters: [ExploreQuickFilter] {
        quickFilterOptions.filter(isSelected)
    }

    private var unselectedQuickFilters: [ExploreQuickFilter] {
        quickFilterOptions.filter { !isSelected($0) }
    }

    private var allFiltersID: String { "all-filters" }

    private func isSelected(_ filter: ExploreQuickFilter) -> Bool {
        selectedValues(for: filter.category).contains(filter.value)
    }

    private func toggle(_ filter: ExploreQuickFilter) {
        var selection = controller.selectedFilters
        var values = selectedValues(for: filter.category, in: selection)

        if values.contains(filter.value) {
            values.remove(filter.value)
        } else {
            values.insert(filter.value)
        }
        setSelectedValues(values, for: filter.category, in: &selection)

        withAnimation(.easeInOut(duration: 0.2)) {
            controller.selectedFilters = selection
        }
    }

    private func selectedValues(
        for category: ExploreQuickFilter.Category,
        in selection: RecipeFilterSelection? = nil
    ) -> Set<String> {
        let selection = selection ?? controller.selectedFilters
        switch category {
        case .cuisine: return selection.cuisines
        case .meal: return selection.mealTypes
        case .dietary: return selection.dietaryTags
        case .difficulty: return selection.difficulties
        case .totalTime: return selection.totalTimes
        case .calories: return selection.calorieRanges
        case .servings: return selection.servingSizes
        }
    }

    private func setSelectedValues(
        _ values: Set<String>,
        for category: ExploreQuickFilter.Category,
        in selection: inout RecipeFilterSelection
    ) {
        switch category {
        case .cuisine: selection.cuisines = values
        case .meal: selection.mealTypes = values
        case .dietary: selection.dietaryTags = values
        case .difficulty: selection.difficulties = values
        case .totalTime: selection.totalTimes = values
        case .calories: selection.calorieRanges = values
        case .servings: selection.servingSizes = values
        }
    }

    private func openRecipe(_ recipe: Recipe) {
        path.append(.overview(RecipeSession(recipe: recipe), nil))
    }
}

private struct ExploreQuickFilter: Identifiable {
    enum Category: String {
        case cuisine
        case meal
        case dietary
        case difficulty
        case totalTime
        case calories
        case servings
    }

    let category: Category
    let value: String

    var id: String { "\(category.rawValue):\(value)" }

    var displayTitle: String {
        switch category {
        case .totalTime, .calories, .servings:
            value
        default:
            value.capitalized
        }
    }
}

#Preview {
    ExploreView()
}
