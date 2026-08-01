//
//  CameraCapture.swift
//  Simmr
//
//  Wraps UIImagePickerController(sourceType: .camera) for a single "photo
//  of your finished dish" — deliberately not DocumentCameraView, which
//  wraps VisionKit's multi-page document scanner tuned for recipe text,
//  not a plain photo. Reuses the existing NSCameraUsageDescription
//  Info.plist key, same as DocumentCameraView.
//
//  Note: this cannot be exercised in the iOS Simulator (no camera
//  hardware) — it only compiles/runs on a physical device.
//

import SwiftUI
import UIKit

struct CameraCapture: UIViewControllerRepresentable {
    var onFinish: (UIImage) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.sourceType = .camera
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish, onCancel: onCancel)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let onFinish: (UIImage) -> Void
        private let onCancel: () -> Void

        init(onFinish: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onFinish = onFinish
            self.onCancel = onCancel
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onFinish(image)
            } else {
                onCancel()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}
