//
//  APIKeySettingsView.swift
//  Simmr
//

import FirebaseAuth
import SwiftUI

struct APIKeySettingsView: View {
    @StateObject private var viewModel = APIKeySettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFieldFocused: Bool
    @State private var isShowingOnboarding = false
    @ObservedObject private var authManager = AuthenticationManager.shared
    @State private var isShowingLogin = false

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

                    SecureField("", text: $viewModel.apiKeyInput, prompt: Text("sk-...").foregroundStyle(Theme.Colors.textMuted))
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textDark)
                        .tint(Theme.Colors.coral)
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

                    Divider()
                        .overlay(Theme.Colors.border)

                    VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                        Text("Account")
                            .font(Theme.Typography.title3)
                            .foregroundStyle(Theme.Colors.textDark)
                        if let email = authManager.currentUser?.email {
                            Text("Signed in as \(email)")
                                .font(Theme.Typography.subheadline)
                                .foregroundStyle(Theme.Colors.textMuted)
                        } else {
                            Text("Not signed in — your recipes and cooking history stay on this device only.")
                                .font(Theme.Typography.subheadline)
                                .foregroundStyle(Theme.Colors.textMuted)
                        }
                    }

                    if authManager.currentUser != nil {
                        Button("Sign Out", role: .destructive) {
                            authManager.signOut()
                        }
                        .buttonStyle(.secondary)
                    } else {
                        Button("Sign In") {
                            isShowingLogin = true
                        }
                        .buttonStyle(.secondary)
                    }

                    Divider()
                        .overlay(Theme.Colors.border)

                    VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                        Text("Kitchen Profile")
                            .font(Theme.Typography.title3)
                            .foregroundStyle(Theme.Colors.textDark)
                        Text("Update your cooking habits, dietary needs, and taste preferences.")
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(Theme.Colors.textMuted)
                    }

                    Button("Edit Kitchen Profile") {
                        isShowingOnboarding = true
                    }
                    .buttonStyle(.secondary)

                    Divider()
                        .overlay(Theme.Colors.border)

                    VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                        HStack {
                            Text("Recipe Prompt")
                                .font(Theme.Typography.title3)
                                .foregroundStyle(Theme.Colors.textDark)
                            if viewModel.isPromptOverridden {
                                Text("Custom")
                                    .font(Theme.Typography.footnote.weight(.semibold))
                                    .foregroundStyle(Theme.Colors.coral)
                                    .padding(.horizontal, Theme.Spacing.xs)
                                    .padding(.vertical, 2)
                                    .background(Theme.Colors.tint)
                                    .clipShape(Capsule())
                            }
                        }
                        Text("For testing only — edit the system prompt sent to OpenAI when generating recipes.")
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(Theme.Colors.textMuted)
                    }

                    TextEditor(text: $viewModel.promptInput)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(Theme.Colors.textDark)
                        .frame(height: 260)
                        .scrollContentBackground(.hidden)
                        .padding(Theme.Spacing.sm)
                        .background(Theme.Colors.creamCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                                .strokeBorder(Theme.Colors.border, lineWidth: Theme.Stroke.regular)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                        .onChange(of: viewModel.promptInput) { _, _ in
                            viewModel.acknowledgePromptEdit()
                        }

                    if viewModel.didSavePrompt {
                        Label("Prompt saved", systemImage: "checkmark.circle.fill")
                            .font(Theme.Typography.footnote)
                            .foregroundStyle(Theme.Colors.amber)
                    }

                    HStack(spacing: Theme.Spacing.sm) {
                        Button("Save Prompt") {
                            viewModel.savePrompt()
                        }
                        .buttonStyle(.primary)

                        Button("Reset to Default", role: .destructive) {
                            viewModel.resetPromptToDefault()
                        }
                        .buttonStyle(.secondary)
                        .disabled(!viewModel.isPromptOverridden)
                    }
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
            .fullScreenCover(isPresented: $isShowingOnboarding) {
                OnboardingContainerView(isEditing: true) {
                    isShowingOnboarding = false
                }
            }
            .fullScreenCover(isPresented: $isShowingLogin) {
                LoginView {
                    isShowingLogin = false
                }
            }
        }
    }
}

#Preview {
    APIKeySettingsView()
}
