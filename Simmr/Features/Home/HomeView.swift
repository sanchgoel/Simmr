//
//  HomeView.swift
//  Simmr
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var path: [AppRoute] = []
    @State private var session: RecipeSession?
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    header
                    pasteField
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
            .scrollDismissesKeyboard(.interactively)
            .navigationDestination(for: AppRoute.self) { route in
                if let session {
                    switch route {
                    case .overview:
                        RecipeOverviewView(session: session, path: $path)
                    case .grocery:
                        GroceryChecklistView(session: session, path: $path)
                    case .cooking:
                        CookingModeView(session: session, path: $path)
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            Text("Simmr")
                .font(Theme.Typography.largeTitle)
                .foregroundStyle(Theme.Colors.textDark)
            Text("Paste a recipe and let's get cooking.")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.textMuted)
        }
        .padding(.top, Theme.Spacing.md)
    }

    private var pasteField: some View {
        ZStack(alignment: .topLeading) {
            if viewModel.pastedText.isEmpty {
                Text("Paste a recipe here — ingredients, steps, anything you've got.")
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
        .frame(minHeight: 260)
        .background(Theme.Colors.creamCard)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                .strokeBorder(isTextFieldFocused ? Theme.Colors.coral : Theme.Colors.border, lineWidth: Theme.Stroke.regular)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
        .animation(.easeInOut(duration: 0.15), value: isTextFieldFocused)
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

#Preview {
    HomeView()
}
