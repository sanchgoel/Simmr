//
//  HomeView.swift
//  Simmr
//
//  Two layouts depending on whether the user has any history yet. First
//  time: nothing to show as a dashboard, so all four creation methods are
//  shown up front as cards — one obvious thing to do. Returning: a
//  cooking-focused dashboard (Continue Cooking + Recent Recipes) with
//  creation methods tucked behind a bottom-pinned CTA instead of competing
//  for space with the content that actually matters once there's history.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var path: [AppRoute] = []
    @State private var isShowingSettings = false
    @State private var isShowingImportFlow = false
    @State private var isShowingNewRecipeSheet = false
    @State private var pendingCreationOption: RecipeCreationOption?
    @State private var importSource: RecipeImportSource?

    /// `initialPath` lets RootView seed Home already inside an in-progress
    /// cook on a cold launch that restored an active CookingSession, instead
    /// of always starting empty — the route itself carries whatever
    /// RecipeSession/CookingSession that destination needs.
    init(initialPath: [AppRoute] = []) {
        _path = State(initialValue: initialPath)
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if !viewModel.hasLoadedSessions {
                    Theme.Colors.creamBackground.ignoresSafeArea()
                } else if viewModel.hasAnyHistory {
                    returningUserContent
                } else {
                    firstTimeContent
                }
            }
            .sheet(isPresented: $isShowingNewRecipeSheet, onDismiss: {
                // Deliberately acted on here rather than inside the sheet's
                // own row-tap closure: triggering another presentation
                // (fullScreenCover/push) in the same synchronous action that
                // also dismisses this sheet races SwiftUI's state commit,
                // and RecipeImportFlowView would read `importSource` as
                // still-nil, falling back to its own internal source
                // picker. Waiting for the system's own onDismiss guarantees
                // this sheet is fully gone first.
                guard let option = pendingCreationOption else { return }
                pendingCreationOption = nil
                switch option {
                case .camera: beginImport(source: .camera)
                case .photos: beginImport(source: .photos)
                case .paste: beginTextEntry(mode: .paste)
                case .dishName: beginTextEntry(mode: .dishName)
                }
            }) {
                NewRecipeOptionsSheet { option in
                    pendingCreationOption = option
                    isShowingNewRecipeSheet = false
                }
                .presentationDetents([.height(340)])
                .presentationDragIndicator(.visible)
                .presentationBackground(Theme.Colors.creamBackground)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Theme.Colors.textDark)
                    }
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
            .fullScreenCover(isPresented: $isShowingImportFlow) {
                RecipeImportFlowView(
                    optimizationOptions: viewModel.optimizationOptions,
                    initialSource: importSource,
                    onRecipeReady: { recipe in
                        isShowingImportFlow = false
                        Task { await handleRecipeReady(recipe) }
                    },
                    onCancelAll: {
                        isShowingImportFlow = false
                    }
                )
            }
            .onAppear {
                Task {
                    await viewModel.refreshSessions()
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .newRecipe(let mode):
                    NewRecipeView(viewModel: viewModel, mode: mode) { recipe in
                        Task { await handleRecipeReady(recipe) }
                    }
                    .toolbar(.hidden, for: .tabBar)
                case .overview(let session, let pendingCookingSession):
                    RecipeOverviewView(session: session, pendingCookingSession: pendingCookingSession, path: $path)
                        .toolbar(.hidden, for: .tabBar)
                case .cooking(let session, let existingCookingSession):
                    CookingModeView(session: session, path: $path, existingCookingSession: existingCookingSession)
                        .toolbar(.hidden, for: .tabBar)
                }
            }
        }
    }

    /// Shared by the paste/dish-name flow and the camera/photo import flow —
    /// both ultimately funnel through this same callback. Persists a
    /// `.notStarted` session immediately, before the user has decided
    /// whether to cook it, so it shows up in Recent Recipes even if they
    /// just look at Overview and go back to Home.
    private func handleRecipeReady(_ recipe: Recipe) async {
        let recipeSession = RecipeSession(recipe: recipe)
        let cookingSession = await viewModel.saveGeneratedRecipe(recipe, servings: recipeSession.servings)
        path.append(.overview(recipeSession, cookingSession))
    }

    private func beginImport(source: RecipeImportSource) {
        importSource = source
        isShowingImportFlow = true
    }

    private func beginTextEntry(mode: NewRecipeMode) {
        path.append(.newRecipe(mode))
    }

    // MARK: - First-time layout (no history yet)

    private var firstTimeContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                header
                createRecipeSection
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Colors.creamBackground.ignoresSafeArea())
    }

    private var createRecipeSection: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: Theme.Spacing.sm), GridItem(.flexible())], spacing: Theme.Spacing.sm) {
            createOptionTile(emoji: "📷", title: "Scan with Camera") { beginImport(source: .camera) }
            createOptionTile(emoji: "🖼", title: "Import Photos") { beginImport(source: .photos) }
            createOptionTile(emoji: "📋", title: "Paste Recipe") { beginTextEntry(mode: .paste) }
            createOptionTile(emoji: "🍳", title: "Type Dish Name") { beginTextEntry(mode: .dishName) }
        }
    }

    private func createOptionTile(emoji: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.xs) {
                Text(emoji)
                    .font(.system(size: 28))
                Text(title)
                    .font(Theme.Typography.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Colors.textDark)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .cardStyle()
    }

    // MARK: - Returning-user layout (dashboard)

    private var returningUserContent: some View {
        List {
            row(header, topPadding: Theme.Spacing.xs, bottomPadding: Theme.Spacing.sm)

            if let resumableSession = viewModel.resumableSession {
                row(
                    ContinueCookingCard(session: resumableSession) {
                        openCookingSession(resumableSession)
                    },
                    bottomPadding: Theme.Spacing.sm
                )
            }

            if !viewModel.recentSessions.isEmpty {
                row(
                    Text("Recent Recipes")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.textDark),
                    bottomPadding: Theme.Spacing.xs
                )

                ForEach(viewModel.recentSessions) { recentSession in
                    row(
                        RecentSessionRow(session: recentSession) {
                            switch recentSession.status {
                            case .active, .paused:
                                openCookingSession(recentSession)
                            case .notStarted, .completed:
                                openForReview(recentSession)
                            }
                        },
                        bottomPadding: Theme.Spacing.xs
                    )
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task { await viewModel.deleteSession(recentSession) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Theme.Colors.creamBackground.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            newRecipeButton
                .padding(Theme.Spacing.lg)
                .background(Theme.Colors.creamBackground)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            Text("Simmr")
                .font(Theme.Typography.largeTitle)
                .foregroundStyle(Theme.Colors.textDark)
            Text("Scan, import, paste, or type a recipe — let's get cooking.")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.textMuted)
        }
    }

    /// Wraps content as a List row with no default List chrome (background,
    /// separator) so the List reads as our usual cream-card layout rather
    /// than a system list — used for every row except where `.swipeActions`
    /// needs the real List row itself (Recent Recipes rows, applied at the
    /// call site).
    private func row(_ content: some View, topPadding: CGFloat = 0, bottomPadding: CGFloat = 0) -> some View {
        content
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: topPadding, leading: Theme.Spacing.lg, bottom: bottomPadding, trailing: Theme.Spacing.lg))
    }

    private var newRecipeButton: some View {
        Button {
            isShowingNewRecipeSheet = true
        } label: {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "plus.circle.fill")
                Text("New Recipe")
            }
        }
        .buttonStyle(.primary)
    }

    /// Reconstructs a RecipeSession from a persisted CookingSession and
    /// jumps straight into Cooking Mode at its saved step/timer state —
    /// used by both the Continue Cooking card and an active/paused recipe
    /// row.
    private func openCookingSession(_ cookingSession: CookingSession) {
        let recipeSession = RecipeSession(recipe: cookingSession.recipe)
        recipeSession.servings = cookingSession.servings
        path.append(.cooking(recipeSession, cookingSession))
    }

    /// Opens a completed or not-yet-started recipe's Overview rather than
    /// resuming cooking. If the user then taps "Start Cooking" there, it
    /// reuses this same session's id (via `restarted()`, a no-op for an
    /// already-fresh `.notStarted` session) so re-cooking a recipe updates
    /// its existing history row instead of creating a duplicate.
    private func openForReview(_ cookingSession: CookingSession) {
        let recipeSession = RecipeSession(recipe: cookingSession.recipe)
        recipeSession.servings = cookingSession.servings
        path.append(.overview(recipeSession, cookingSession.restarted()))
    }
}

#Preview {
    HomeView()
}
