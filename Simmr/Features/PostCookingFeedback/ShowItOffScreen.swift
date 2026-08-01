//
//  ShowItOffScreen.swift
//  Simmr
//
//  Screen 2 of the positive flow. Add Photo and Share are optional side
//  actions — Skip is the one forward action on this screen and works
//  regardless of whether either was used first (matches the spec: sharing
//  never requires a photo, and Skip "moves directly to the App Store
//  prompt").
//

import PhotosUI
import SwiftUI

struct ShowItOffScreen: View {
    @ObservedObject var viewModel: PostCookingFeedbackViewModel

    @State private var isShowingPhotoSourceDialog = false
    @State private var isShowingCamera = false
    @State private var isShowingPhotosPicker = false
    @State private var photosSelection: PhotosPickerItem?

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            CelebrationHeaderView(title: headerTitle, subtitle: headerSubtitle)

            if let pickedPhoto = viewModel.pickedPhoto {
                Image(uiImage: pickedPhoto)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 160, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                            .strokeBorder(Theme.Colors.border, lineWidth: Theme.Stroke.regular)
                    )
            }

            Spacer()

            VStack(spacing: Theme.Spacing.sm) {
                Button(viewModel.pickedPhoto == nil ? "📷 Add Photo" : "📷 Retake Photo") {
                    isShowingPhotoSourceDialog = true
                }
                .buttonStyle(.secondary)

                Button("📤 Share Your Cook", action: viewModel.presentShareSheet)
                    .buttonStyle(.primary)

                Button("Skip", action: viewModel.advanceFromShowItOff)
                    .font(Theme.Typography.footnote.weight(.semibold))
                    .foregroundStyle(Theme.Colors.textMuted)
                    .padding(.top, Theme.Spacing.xs)
            }
        }
        .padding(Theme.Spacing.lg)
        .confirmationDialog("Add Photo", isPresented: $isShowingPhotoSourceDialog, titleVisibility: .visible) {
            Button("📷 Take Photo") { isShowingCamera = true }
            Button("🖼 Choose from Library") { isShowingPhotosPicker = true }
            Button("Cancel", role: .cancel) {}
        }
        .fullScreenCover(isPresented: $isShowingCamera) {
            CameraCapture(
                onFinish: { image in
                    isShowingCamera = false
                    viewModel.addPhoto(image)
                },
                onCancel: { isShowingCamera = false }
            )
            .ignoresSafeArea()
        }
        .photosPicker(isPresented: $isShowingPhotosPicker, selection: $photosSelection, matching: .images)
        .onChange(of: photosSelection) { _, newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    viewModel.addPhoto(image)
                }
                photosSelection = nil
            }
        }
    }

    private var headerTitle: String {
        (viewModel.rating ?? 0) == 5 ? "You nailed it! 🎉" : "That looks like a win 🙌"
    }

    private var headerSubtitle: String {
        (viewModel.rating ?? 0) == 5 ? "That dish deserves its moment." : "Go on, show off what you made."
    }
}
