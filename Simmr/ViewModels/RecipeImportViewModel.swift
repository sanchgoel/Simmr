//
//  RecipeImportViewModel.swift
//  Simmr
//
//  Orchestrates the import pipeline: RecipeTextExtracting (Vision OCR) ->
//  RecipeGenerating.generateRecipe(from:options:) — the exact same entry
//  point the paste-text flow already uses, so personalization,
//  optimization instructions, and the OpenAI call are all shared, unchanged
//  code paths.
//

import Combine
import Foundation

enum ImportPhase: Equatable {
    /// Real progress — OCR runs locally, so we know exactly how far along it is.
    case readingImages(done: Int, total: Int)
    /// The OpenAI call is a single non-streamed request, so this phase has
    /// no real progress to report — the UI cycles cosmetic messages instead.
    case parsingRecipe
}

@MainActor
final class RecipeImportViewModel: ObservableObject {
    @Published private(set) var phase: ImportPhase?
    @Published var errorMessage: String?
    @Published var skippedPageWarning: String?

    private let textExtractor: RecipeTextExtracting
    private let recipeProvider: RecipeGenerating

    init(textExtractor: RecipeTextExtracting? = nil, recipeProvider: RecipeGenerating? = nil) {
        self.textExtractor = textExtractor ?? VisionRecipeTextExtractor()
        self.recipeProvider = recipeProvider ?? RecipeParserService()
    }

    var isProcessing: Bool { phase != nil }

    /// Runs the full OCR + parsing pipeline for the given pages, in the
    /// order provided. Returns nil (with `errorMessage` set) on failure.
    func runImport(pages: [CapturedPage], options: RecipeOptimizationOptions) async -> Recipe? {
        errorMessage = nil
        skippedPageWarning = nil
        let images = pages.map(\.image)

        phase = .readingImages(done: 0, total: images.count)
        let extraction: OCRExtractionResult
        do {
            extraction = try await textExtractor.extractText(from: images) { [weak self] done, total in
                self?.phase = .readingImages(done: done, total: total)
            }
        } catch let error as LocalizedError {
            errorMessage = error.errorDescription ?? "Couldn't read this recipe. Please try again."
            phase = nil
            return nil
        } catch {
            errorMessage = "Couldn't read this recipe. Please try again."
            phase = nil
            return nil
        }

        if extraction.hasUnreadablePages {
            skippedPageWarning = "\(extraction.unreadablePageCount) of \(extraction.totalPageCount) pages couldn't be read and were skipped."
        }

        phase = .parsingRecipe
        do {
            let recipe = try await recipeProvider.generateRecipe(from: extraction.combinedText, options: options)
            phase = nil
            return recipe
        } catch let error as LocalizedError {
            errorMessage = error.errorDescription ?? "Couldn't generate a recipe. Please try again."
            phase = nil
            return nil
        } catch {
            errorMessage = "Couldn't generate a recipe. Please try again."
            phase = nil
            return nil
        }
    }
}
