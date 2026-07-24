//
//  HomeView.swift
//  Simmr
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var path: [AppRoute] = []
    @State private var session: RecipeSession?
    @State private var isShowingSettings = false
    @State private var isShowingImportFlow = false
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    header
                    importRecipeButton
                    orDivider
                    pasteField
                    optimizationToggles
                    if !viewModel.hasAPIKey {
                        apiKeyPrompt
                    }
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(Theme.Typography.footnote)
                            .foregroundStyle(Theme.Colors.coral)
                    }
                    generateButton
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Theme.Colors.creamBackground.ignoresSafeArea())
            .contentShape(Rectangle())
            .onTapGesture {
                isTextFieldFocused = false
            }
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Theme.Colors.textDark)
                    }
                }
            }
            .sheet(isPresented: $isShowingSettings, onDismiss: {
                viewModel.refreshAPIKeyStatus()
            }) {
                APIKeySettingsView()
            }
            .fullScreenCover(isPresented: $isShowingImportFlow) {
                RecipeImportFlowView(
                    optimizationOptions: viewModel.optimizationOptions,
                    onRecipeReady: { recipe in
                        session = RecipeSession(recipe: recipe)
                        isShowingImportFlow = false
                        path.append(.overview)
                    },
                    onCancelAll: {
                        isShowingImportFlow = false
                    }
                )
            }
            .navigationDestination(for: AppRoute.self) { route in
                if let session {
                    switch route {
                    case .overview:
                        RecipeOverviewView(session: session, path: $path)
                    case .cooking:
                        CookingModeView(session: session, path: $path)
                    }
                }
            }
        }
        .overlay {
            if viewModel.isGenerating {
                RecipeGeneratingOverlay()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.isGenerating)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            Text("Simmr")
                .font(Theme.Typography.largeTitle)
                .foregroundStyle(Theme.Colors.textDark)
            Text("Paste a recipe or just type a dish name — let's get cooking.")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.textMuted)
        }
        .padding(.top, Theme.Spacing.md)
    }

    private var importRecipeButton: some View {
        Button {
            isTextFieldFocused = false
            isShowingImportFlow = true
        } label: {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "camera.fill")
                Text("Import Recipe")
            }
        }
        .buttonStyle(.secondary)
    }

    private var orDivider: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Rectangle().fill(Theme.Colors.border).frame(height: Theme.Stroke.regular)
            Text("or paste a recipe below")
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Colors.textMuted)
                .fixedSize()
            Rectangle().fill(Theme.Colors.border).frame(height: Theme.Stroke.regular)
        }
    }

    private var pasteField: some View {
        ZStack(alignment: .topLeading) {
            if viewModel.pastedText.isEmpty {
                Text("Paste a full recipe, or just type a dish name like \"spicy chicken curry\".")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textMuted)
                    .padding(.horizontal, Theme.Spacing.sm + 4)
                    .padding(.vertical, Theme.Spacing.sm + 4)
            }

            TextEditor(text: $viewModel.pastedText)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textDark)
                .focused($isTextFieldFocused)
                .scrollContentBackground(.hidden)
                .padding(Theme.Spacing.sm)
        }
        .frame(height: 260)
        .background(Theme.Colors.creamCard)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                .strokeBorder(isTextFieldFocused ? Theme.Colors.coral : Theme.Colors.border, lineWidth: Theme.Stroke.regular)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
        .animation(.easeInOut(duration: 0.15), value: isTextFieldFocused)
    }

    private var optimizationToggles: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Select what to optimize")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.textDark)

            FlowLayout(spacing: Theme.Spacing.xs) {
                optimizationChip(title: "Lower calories", option: .lowerCalories)
                optimizationChip(title: "More protein", option: .higherProtein)
                optimizationChip(title: "Less sugar", option: .lowerSugar)
                optimizationChip(title: "Low carb", option: .lowCarb)
                optimizationChip(title: "Dairy free", option: .dairyFree)
                optimizationChip(title: "More spicy", option: .spicier)
                optimizationChip(title: "Kid friendly", option: .kidFriendly)
            }
        }
    }

    private func optimizationChip(title: String, option: RecipeOptimizationOptions) -> some View {
        let isSelected = viewModel.optimizationOptions.contains(option)
        return Button {
            viewModel.toggleOptimization(option)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(Theme.Typography.footnote.weight(.semibold))
            }
            .foregroundStyle(isSelected ? .white : Theme.Colors.coral)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(isSelected ? Theme.Colors.coral : Theme.Colors.tint)
            .overlay(
                Capsule().strokeBorder(isSelected ? Color.clear : Theme.Colors.coral.opacity(0.35), lineWidth: Theme.Stroke.regular)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(ChipButtonStyle())
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private var apiKeyPrompt: some View {
        Button {
            isShowingSettings = true
        } label: {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "key.fill")
                Text("Add your OpenAI API key to generate recipes")
                    .font(Theme.Typography.footnote)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(Theme.Colors.textDark)
            .padding(Theme.Spacing.sm)
            .background(Theme.Colors.tint)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var generateButton: some View {
        Button {
            isTextFieldFocused = false
            Task {
                if let recipe = await viewModel.generateRecipe() {
                    session = RecipeSession(recipe: recipe)
                    path.append(.overview)
                }
            }
        } label: {
            HStack(spacing: Theme.Spacing.xs) {
                if viewModel.isGenerating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Generate Recipe")
                }
            }
        }
        .buttonStyle(.primary)
        .disabled(!viewModel.canGenerate)
        .opacity(viewModel.canGenerate ? 1 : 0.6)
    }
}

/// Scales down slightly on press so the optimization chips read as tappable.
private struct ChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    HomeView()
}
