//
//  APIKeySettingsView.swift
//  Simmr
//

import SwiftUI

struct APIKeySettingsView: View {
    @StateObject private var viewModel = APIKeySettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                        Text("OpenAI API Key")
                            .font(Theme.Typography.title3)
                            .foregroundStyle(Theme.Colors.textDark)
                        Text("Simmr uses your own OpenAI key to parse pasted recipes. It's stored securely in the Keychain on this device only.")
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(Theme.Colors.textMuted)
                    }

                    SecureField("sk-...", text: $viewModel.apiKeyInput)
                        .font(Theme.Typography.body)
                        .focused($isFieldFocused)
                        .padding(Theme.Spacing.sm)
                        .background(Theme.Colors.creamCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                                .strokeBorder(isFieldFocused ? Theme.Colors.coral : Theme.Colors.border, lineWidth: Theme.Stroke.regular)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(Theme.Typography.footnote)
                            .foregroundStyle(Theme.Colors.coral)
                    }

                    if viewModel.isSaved {
                        Label("Key saved", systemImage: "checkmark.circle.fill")
                            .font(Theme.Typography.footnote)
                            .foregroundStyle(Theme.Colors.amber)
                    }

                    VStack(spacing: Theme.Spacing.sm) {
                        Button("Save") {
                            isFieldFocused = false
                            viewModel.save()
                        }
                        .buttonStyle(.primary)
                        .disabled(!viewModel.canSave)
                        .opacity(viewModel.canSave ? 1 : 0.6)

                        if viewModel.isSaved {
                            Button("Remove Key", role: .destructive) {
                                viewModel.clear()
                            }
                            .buttonStyle(.secondary)
                        }
                    }

                    Link("Get an API key from platform.openai.com", destination: URL(string: "https://platform.openai.com/api-keys")!)
                        .font(Theme.Typography.footnote)
                        .foregroundStyle(Theme.Colors.coral)
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Theme.Colors.creamBackground.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    APIKeySettingsView()
}
