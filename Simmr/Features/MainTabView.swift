//
//  MainTabView.swift
//  Simmr
//
//  Persistent top-level navigation shown after onboarding.
//

import SwiftUI

private enum MainTab: Hashable {
    case home
    case explore
}

struct MainTabView: View {
    @State private var selectedTab: MainTab = .home
    private let initialHomePath: [AppRoute]

    init(initialHomePath: [AppRoute] = []) {
        self.initialHomePath = initialHomePath
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(initialPath: initialHomePath)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(MainTab.home)

            ExploreView()
                .tabItem {
                    Label("Explore", systemImage: "safari")
                }
                .tag(MainTab.explore)
        }
        .tint(Theme.Colors.coral)
    }
}

#Preview {
    MainTabView()
}
