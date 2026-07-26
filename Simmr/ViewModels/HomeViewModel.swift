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
    @Published private(set) var hasAPIKey: Bool
    /// The most recently updated active-or-paused session, if any — drives
    /// the "Continue Cooking" card. Deliberately excludes `.notStarted`: a
    /// generated-but-never-begun recipe belongs in Recent Recipes, not
    /// presented as something to "continue."
    @Published private(set) var resumableSession: CookingSession?
    /// All sessions (active, paused, and completed), most recent first,
    /// capped for display — drives the "Recent Recipes" section.
    @Published private(set) var recentSessions: [CookingSession] = []

    /// Whether the user has ever generated/cooked anything — decides
    /// between the first-time layout (all four creation options shown up
    /// front) and the returning-user dashboard (Continue Cooking + Recent
    /// Recipes, creation methods tucked behind the bottom CTA).
    var hasAnyHistory: Bool {
        resumableSession != nil || !recentSessions.isEmpty
    }

    private let recipeProvider: RecipeGenerating
    private let apiKeyStore: APIKeyStoring
    private let cookingSessionRepository: CookingSessionRepository

    init(
        recipeProvider: RecipeGenerating? = nil,
        apiKeyStore: APIKeyStoring? = nil,
        cookingSessionRepository: CookingSessionRepository? = nil
    ) {
        let apiKeyStore = apiKeyStore ?? KeychainAPIKeyStore()
        self.apiKeyStore = apiKeyStore
        self.recipeProvider = recipeProvider ?? RecipeParserService(apiKeyStore: apiKeyStore)
        self.hasAPIKey = apiKeyStore.apiKey?.isEmpty == false
        self.cookingSessionRepository = cookingSessionRepository ?? LocalCookingSessionRepository()
    }

    /// Refreshes Continue Cooking / Recent Recipes — called whenever Home
    /// becomes visible again (including popping back from Cooking/Overview),
    /// since finishing or backing out of a cook should immediately move it
    /// between the two sections.
    func refreshSessions() async {
        guard let sessions = try? await cookingSessionRepository.fetchAllSessions() else { return }
        resumableSession = sessions.first { $0.status == .active || $0.status == .paused }
        recentSessions = Array(sessions.prefix(10))
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

    func refreshAPIKeyStatus() {
        hasAPIKey = apiKeyStore.apiKey?.isEmpty == false
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
