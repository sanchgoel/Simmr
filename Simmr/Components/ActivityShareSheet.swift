//
//  ActivityShareSheet.swift
//  Simmr
//
//  Wraps UIActivityViewController rather than SwiftUI's ShareLink, since
//  ShareLink's typed Transferable API can't cleanly mix a String and a
//  UIImage in one share, and this needs to support both "text only" and
//  "text + photo" depending on whether the user added a photo.
//

import SwiftUI
import UIKit

/// Identifiable wrapper so this can be driven by `.sheet(item:)`.
struct ShareContent: Identifiable {
    let id = UUID()
    let text: String
    let image: UIImage?

    var activityItems: [Any] {
        image.map { [text, $0] } ?? [text]
    }
}

struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    /// `completed` is false for a cancelled/dismissed share, true only once
    /// the user actually finished sharing through some activity — this is
    /// how "Share Completed" is measurable at all.
    var onComplete: ((_ completed: Bool) -> Void)?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in
            onComplete?(completed)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
