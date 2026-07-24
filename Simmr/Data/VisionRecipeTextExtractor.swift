//
//  VisionRecipeTextExtractor.swift
//  Simmr
//
//  RecipeTextExtracting conformer using Apple's Vision OCR
//  (VNRecognizeTextRequest). Runs off the main actor since text
//  recognition is a synchronous, CPU-bound call that would otherwise
//  block the UI (this project defaults new types to @MainActor isolation).
//

import Foundation
import UIKit
import Vision

struct VisionRecipeTextExtractor: RecipeTextExtracting {
    /// Below this per-image confidence (or below the minimum line count),
    /// a page is treated as unreadable and dropped from the combined text.
    private static let minimumPageConfidence: Double = 0.35
    private static let minimumPageLineCount = 3
    /// Below this overall confidence across all readable pages, the whole
    /// import is treated as having failed rather than handing OpenAI a
    /// combined text block.
    private static let minimumOverallConfidence: Double = 0.25

    func extractText(
        from images: [UIImage],
        onProgress: @escaping @MainActor (_ completed: Int, _ total: Int) -> Void
    ) async throws -> OCRExtractionResult {
        var pageTexts: [String] = []
        var confidences: [Double] = []
        var unreadableCount = 0

        for (index, image) in images.enumerated() {
            let (text, confidence) = try await Task.detached(priority: .userInitiated) {
                try Self.recognizeText(in: image)
            }.value

            let lineCount = text.split(separator: "\n", omittingEmptySubsequences: true).count
            let isReadable = confidence >= Self.minimumPageConfidence && lineCount >= Self.minimumPageLineCount

            if isReadable {
                pageTexts.append("--- Page \(index + 1) ---\n\(text)")
                confidences.append(confidence)
            } else {
                unreadableCount += 1
            }

            await onProgress(index + 1, images.count)
        }

        let combinedText = pageTexts.joined(separator: "\n\n")
        let overallConfidence = confidences.isEmpty ? 0 : confidences.reduce(0, +) / Double(confidences.count)

        guard !combinedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              overallConfidence >= Self.minimumOverallConfidence,
              unreadableCount < images.count
        else {
            throw RecipeTextExtractingError.noReadableText
        }

        return OCRExtractionResult(
            combinedText: combinedText,
            totalPageCount: images.count,
            unreadablePageCount: unreadableCount
        )
    }

    /// Synchronous Vision recognition for a single image — safe to call
    /// off the main actor since it does no UI work. Vision returns
    /// observations top-to-bottom for standard page layouts, which is
    /// preserved by joining them in results order.
    private static func recognizeText(in image: UIImage) throws -> (text: String, confidence: Double) {
        guard let cgImage = image.cgImage else { return ("", 0) }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let observations = request.results, !observations.isEmpty else { return ("", 0) }

        var lines: [String] = []
        var confidenceSum: Double = 0
        for observation in observations {
            guard let candidate = observation.topCandidates(1).first else { continue }
            lines.append(candidate.string)
            confidenceSum += Double(candidate.confidence)
        }

        let averageConfidence = lines.isEmpty ? 0 : confidenceSum / Double(lines.count)
        return (lines.joined(separator: "\n"), averageConfidence)
    }
}
