//
//  RecipeTextExtracting.swift
//  Simmr
//
//  Abstraction over "turn a set of recipe page images into one raw text
//  block" — mirrors RecipeGenerating's pattern so the OCR step is just as
//  swappable/testable. VisionRecipeTextExtractor is the live conformer.
//

import Foundation
import UIKit

protocol RecipeTextExtracting {
    /// Extracts and combines text from `images` in the given order, calling
    /// `onProgress` after each image finishes (for real progress reporting
    /// in the UI). Throws `RecipeTextExtractingError.noReadableText` if no
    /// image yielded usable text.
    func extractText(
        from images: [UIImage],
        onProgress: @escaping @MainActor (_ completed: Int, _ total: Int) -> Void
    ) async throws -> OCRExtractionResult
}

struct OCRExtractionResult {
    /// All readable pages' text, joined with page markers. Empty pages are
    /// omitted entirely (see RecipeTextExtractingError.noReadableText for
    /// when this can't be empty).
    let combinedText: String
    let totalPageCount: Int
    let unreadablePageCount: Int

    var hasUnreadablePages: Bool { unreadablePageCount > 0 }
}

enum RecipeTextExtractingError: LocalizedError {
    case noReadableText

    var errorDescription: String? {
        switch self {
        case .noReadableText:
            return "We couldn't confidently read this recipe. Try taking clearer photos."
        }
    }
}
