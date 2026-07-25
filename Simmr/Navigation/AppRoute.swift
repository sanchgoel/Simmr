//
//  AppRoute.swift
//  Simmr
//

import Foundation

enum AppRoute: Hashable {
    /// Carries its mode directly rather than HomeView reading a sibling
    /// @State var — a value set immediately before `path.append(...)` in
    /// the same synchronous call isn't reliably visible yet when
    /// `.navigationDestination(for:)` builds the pushed view, so the mode
    /// has to travel on the route itself instead.
    case newRecipe(NewRecipeMode)
    case overview
    case cooking
}
