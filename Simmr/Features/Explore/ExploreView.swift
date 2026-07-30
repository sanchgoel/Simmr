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

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                        Text("Explore")
                            .font(Theme.Typography.largeTitle)
                            .foregroundStyle(Theme.Colors.textDark)

                        Text("Discover recipes picked for every kind of craving.")
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(Theme.Colors.textMuted)
                    }

                    RecipeCollectionsSection(
                        controller: controller,
                        onSelectRecipe: openRecipe
                    )
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Theme.Colors.creamBackground.ignoresSafeArea())
            .task {
                await controller.loadIfNeeded()
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

    private func openRecipe(_ recipe: Recipe) {
        path.append(.overview(RecipeSession(recipe: recipe), nil))
    }
}

#Preview {
    ExploreView()
}
