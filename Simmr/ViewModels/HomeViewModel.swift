//
//  HomeViewModel.swift
//  Simmr
//

import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var pastedText: String = ""
    @Published var optimizationOptions: RecipeOptimizationOptions = []
    @Published private(set) var isGenerating: Bool = false
    @Published var errorMessage: String?
    /// The most recently updated active-or-paused session, if any — drives
    /// the "Continue Cooking" card. Deliberately excludes `.notStarted`: a
    /// generated-but-never-begun recipe belongs in Recent Recipes, not
    /// presented as something to "continue."
    @Published private(set) var resumableSession: CookingSession?
    /// All sessions (active, paused, and completed), most recent first,
    /// capped for display — drives the "Recent Recipes" section.
    @Published private(set) var recentSessions: [CookingSession] = []
    /// False only for the brief window before the very first
    /// `refreshSessions()` resolves — lets HomeView hold off choosing between
    /// its first-time and returning-user layouts until it actually knows
    /// which one is correct, instead of flashing first-time (the two
    /// `@Published` arrays' default empty state) for a frame before the
    /// real data lands.
    @Published private(set) var hasLoadedSessions = false

    /// Whether the user has ever generated/cooked anything — decides
    /// between the first-time layout (all four creation options shown up
    /// front) and the returning-user dashboard (Continue Cooking + Recent
    /// Recipes, creation methods tucked behind the bottom CTA).
    var hasAnyHistory: Bool {
        resumableSession != nil || !recentSessions.isEmpty
    }

    private let recipeProvider: RecipeGenerating
    private let cookingSessionRepository: CookingSessionRepository

    init(
        recipeProvider: RecipeGenerating? = nil,
        cookingSessionRepository: CookingSessionRepository? = nil
    ) {
        self.recipeProvider = recipeProvider ?? BackendRecipeService()
        self.cookingSessionRepository = cookingSessionRepository ?? LocalCookingSessionRepository()
    }

    /// Refreshes Continue Cooking / Recent Recipes — called whenever Home
    /// becomes visible again (including popping back from Cooking/Overview),
    /// since finishing or backing out of a cook should immediately move it
    /// between the two sections.
    func refreshSessions() async {
        let startedAt = Date()
        var sessions: [CookingSession] = []
        var fetchError: String?
        do {
            sessions = try await cookingSessionRepository.fetchAllSessions()
        } catch {
            fetchError = "\(error)"
        }
        APIDebugLogStore.shared.log(APICallLog(
            timestamp: startedAt,
            endpoint: "Home refreshSessions",
            model: nil,
            requestBody: nil,
            statusCode: nil,
            responseBody: "found \(sessions.count) session(s): \(sessions.map { $0.id.uuidString }.joined(separator: ", "))",
            error: fetchError,
            duration: Date().timeIntervalSince(startedAt)
        ))
        guard fetchError == nil else { return }
        resumableSession = sessions.first { $0.status == .active || $0.status == .paused }
        recentSessions = Array(sessions.prefix(10))
        hasLoadedSessions = true
    }

    /// Persists a freshly generated/imported recipe immediately, before the
    /// user has decided whether to start cooking it — so it shows up in
    /// Recent Recipes even if they just look at Overview and go back to
    /// Home. Returns the saved session so the caller can hand it to
    /// CookingModeView later if "Start Cooking" is tapped, reusing this
    /// same id instead of minting a new one.
    func saveGeneratedRecipe(_ recipe: Recipe, servings: Int) async -> CookingSession {
        let now = Date()
        let session = CookingSession(
            id: UUID(),
            recipe: recipe,
            currentStepIndex: 0,
            completedStepIndices: [],
            servings: servings,
            timerEndDate: nil,
            timerRemainingSeconds: recipe.steps.first?.timerSeconds ?? 0,
            isTimerRunning: false,
            isTimerComplete: false,
            timerTotalOverride: nil,
            startedAt: now,
            updatedAt: now,
            status: .notStarted
        )
        try? await cookingSessionRepository.save(session)
        await refreshSessions()
        return session
    }

    /// Removes a session from history (swipe-to-delete on a Recent Recipes
    /// row) and refreshes so it disappears immediately.
    func deleteSession(_ session: CookingSession) async {
        try? await cookingSessionRepository.delete(id: session.id)
        await refreshSessions()
    }

    var canGenerate: Bool {
        !pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isGenerating
    }

    func toggleOptimization(_ option: RecipeOptimizationOptions) {
        if optimizationOptions.contains(option) {
            optimizationOptions.remove(option)
        } else {
            optimizationOptions.insert(option)
        }
    }

    /// `pastedText`/`optimizationOptions`/`errorMessage` live here rather
    /// than as `@State` on NewRecipeView because HomeViewModel is a single
    /// long-lived @StateObject owned by HomeView, not recreated per push —
    /// so NewRecipeView.onAppear calls this to start each visit clean
    /// instead of showing whatever was typed the last time the screen was
    /// open.
    func resetNewRecipeInput() {
        pastedText = ""
        optimizationOptions = []
        errorMessage = nil
    }

    func generateRecipe() async -> Recipe? {
        guard canGenerate else { return nil }
        isGenerating = true
        errorMessage = nil
        defer { isGenerating = false }

        do {
            return try await recipeProvider.generateRecipe(from: pastedText, options: optimizationOptions)
        } catch let error as LocalizedError {
            errorMessage = error.errorDescription ?? "Couldn't generate a recipe. Please try again."
            return nil
        } catch {
            errorMessage = "Couldn't generate a recipe. Please try again."
            return nil
        }
    }
}
