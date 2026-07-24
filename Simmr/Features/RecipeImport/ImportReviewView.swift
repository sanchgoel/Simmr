//
//  ImportReviewView.swift
//  Simmr
//
//  Shared thumbnail/reorder/delete/retake/add-more/done screen used by
//  both the camera-scan and photo-library import paths. Edit mode is
//  always on (rather than needing an Edit/Done toggle) since reviewing
//  and reordering pages is this screen's whole purpose.
//

import SwiftUI

struct ImportReviewView: View {
    @Binding var pages: [CapturedPage]
    let addMoreTitle: String
    /// Retake only makes sense for camera-captured pages, not library picks.
    let allowsRetake: Bool
    var onAddMore: () -> Void
    var onRetake: (CapturedPage.ID) -> Void
    var onDone: () -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(uiImage: page.image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 56, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                                    .strokeBorder(Theme.Colors.border, lineWidth: Theme.Stroke.regular)
                            )

                        Text("Page \(index + 1)")
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(Theme.Colors.textDark)

                        Spacer()

                        if allowsRetake {
                            Button {
                                onRetake(page.id)
                            } label: {
                                Image(systemName: "camera.rotate")
                                    .foregroundStyle(Theme.Colors.coral)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listRowBackground(Theme.Colors.creamBackground)
                }
                .onMove { indices, newOffset in
                    pages.move(fromOffsets: indices, toOffset: newOffset)
                }
                .onDelete { indices in
                    pages.remove(atOffsets: indices)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.editMode, .constant(.active))
            .background(Theme.Colors.creamBackground.ignoresSafeArea())
            .navigationTitle("Review Pages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", action: onCancel)
                        .foregroundStyle(Theme.Colors.textMuted)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(addMoreTitle, action: onAddMore)
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: Theme.Spacing.xs) {
                    Text("\(pages.count) page\(pages.count == 1 ? "" : "s")")
                        .font(Theme.Typography.footnote)
                        .foregroundStyle(Theme.Colors.textMuted)

                    Button("Done") {
                        onDone()
                    }
                    .buttonStyle(.primary)
                    .disabled(pages.isEmpty)
                    .opacity(pages.isEmpty ? 0.6 : 1)
                }
                .padding(Theme.Spacing.lg)
                .background(Theme.Colors.creamBackground)
            }
        }
    }
}
