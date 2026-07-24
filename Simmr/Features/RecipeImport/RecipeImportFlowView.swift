//
//  RecipeImportFlowView.swift
//  Simmr
//
//  Coordinates the whole "Import Recipe" flow: source picker -> camera scan
//  or photo library picker -> shared review (reorder/delete/retake/add
//  more) -> OCR + AI parsing -> hands the resulting Recipe back to
//  HomeView via `onRecipeReady`, which does the exact same
//  `session = RecipeSession(recipe:); path.append(.overview)` the
//  paste-text flow already does. Deliberately just a few @State flags
//  rather than a generic wizard framework — the flow is linear enough not
//  to need one.
//

import PhotosUI
import SwiftUI

struct RecipeImportFlowView: View {
    let optimizationOptions: RecipeOptimizationOptions
    var onRecipeReady: (Recipe) -> Void
    var onCancelAll: () -> Void

    @StateObject private var importViewModel = RecipeImportViewModel()

    @State private var isShowingSourceSheet = true
    @State private var isShowingCamera = false
    @State private var isShowingPhotosPicker = false
    @State private var isShowingReview = false
    @State private var pages: [CapturedPage] = []
    @State private var source: ImportSource?
    @State private var retakePageID: CapturedPage.ID?
    @State private var photosSelection: [PhotosPickerItem] = []

    private enum ImportSource {
        case camera
        case photos
    }

    private static let importMessages = [
        "Cleaning recipe…",
        "Organizing ingredients…",
        "Creating grocery list…",
        "Building cooking steps…",
    ]

    var body: some View {
        ZStack {
            Theme.Colors.creamBackground.ignoresSafeArea()

            if isShowingReview {
                ImportReviewView(
                    pages: $pages,
                    addMoreTitle: source == .camera ? "Take More" : "Add More",
                    allowsRetake: source == .camera,
                    onAddMore: handleAddMore,
                    onRetake: beginRetake,
                    onDone: { Task { await processImport() } },
                    onCancel: onCancelAll
                )
            }
        }
        .confirmationDialog("Import Recipe", isPresented: $isShowingSourceSheet, titleVisibility: .visible) {
            Button("📷 Take Photos") { beginCamera() }
            Button("🖼 Import from Photos") { isShowingPhotosPicker = true }
            Button("Cancel", role: .cancel) { onCancelAll() }
        }
        .fullScreenCover(isPresented: $isShowingCamera) {
            DocumentCameraView(onFinish: handleCameraFinish, onCancel: handleCameraCancel)
                .ignoresSafeArea()
        }
        .photosPicker(isPresented: $isShowingPhotosPicker, selection: $photosSelection, matching: .images)
        .onChange(of: photosSelection) { _, newValue in
            guard !newValue.isEmpty else { return }
            Task { await handlePhotosSelection(newValue) }
        }
        .overlay {
            if importViewModel.isProcessing {
                RecipeGeneratingOverlay(progress: importViewModel.phase, messages: Self.importMessages)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: importViewModel.isProcessing)
        .alert("Couldn't Import Recipe", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importViewModel.errorMessage ?? "")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { importViewModel.errorMessage != nil },
            set: { isPresented in if !isPresented { importViewModel.errorMessage = nil } }
        )
    }

    // MARK: - Camera

    private func beginCamera() {
        source = .camera
        isShowingCamera = true
    }

    private func beginRetake(_ pageID: CapturedPage.ID) {
        retakePageID = pageID
        isShowingCamera = true
    }

    private func handleCameraFinish(_ images: [UIImage]) {
        isShowingCamera = false
        guard let firstImage = images.first else { return }

        if let retakeID = retakePageID {
            if let index = pages.firstIndex(where: { $0.id == retakeID }) {
                pages[index] = CapturedPage(id: retakeID, image: firstImage)
            }
            retakePageID = nil
        } else {
            pages.append(contentsOf: images.map { CapturedPage(image: $0) })
        }

        source = .camera
        isShowingReview = true
    }

    private func handleCameraCancel() {
        isShowingCamera = false
        retakePageID = nil
        if pages.isEmpty {
            onCancelAll()
        }
    }

    // MARK: - Photos

    private func handleAddMore() {
        switch source {
        case .camera:
            isShowingCamera = true
        case .photos, nil:
            isShowingPhotosPicker = true
        }
    }

    private func handlePhotosSelection(_ items: [PhotosPickerItem]) async {
        var newPages: [CapturedPage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                newPages.append(CapturedPage(image: image))
            }
        }
        pages.append(contentsOf: newPages)
        photosSelection = []
        source = .photos
        isShowingReview = true
    }

    // MARK: - Processing

    private func processImport() async {
        guard let recipe = await importViewModel.runImport(pages: pages, options: optimizationOptions) else {
            return
        }
        onRecipeReady(recipe)
    }
}
