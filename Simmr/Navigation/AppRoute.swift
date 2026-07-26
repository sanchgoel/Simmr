//
//  AppRoute.swift
//  Simmr
//

import Foundation

enum AppRoute: Hashable {
    /// Every case carries its data directly rather than HomeView reading a
    /// sibling @State var — a value set immediately before `path.append(...)`
    /// in the same synchronous call isn't reliably visible yet when
    /// `.navigationDestination(for:)` builds the pushed view, so the data
    /// has to travel on the route itself instead.
    case newRecipe(NewRecipeMode)
    /// `RecipeSession` for the screen itself; the optional `CookingSession`
    /// is just staged for forwarding on to `.cooking` if "Start Cooking" is
    /// tapped here — Overview doesn't read it.
    case overview(RecipeSession, CookingSession?)
    case cooking(RecipeSession, CookingSession?)
}
