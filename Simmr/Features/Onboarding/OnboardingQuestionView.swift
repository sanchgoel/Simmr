//
//  OnboardingQuestionView.swift
//  Simmr
//
//  Generic renderer for every question kind (single-select, capped
//  multi-select, grouped multi-select, ranking) so the flow doesn't need a
//  bespoke view per question.
//

import SwiftUI

struct OnboardingQuestionView: View {
    let question: OnboardingQuestion
    @ObservedObject var viewModel: OnboardingViewModel

    @State private var otherText: String = ""
    @FocusState private var isOtherFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    header
                    optionsList
                    if question.allowsOtherText {
                        otherTextField
                    }
                }
                .padding(Theme.Spacing.lg)
            }

            Button("Continue") {
                isOtherFieldFocused = false
                viewModel.goNext()
            }
            .buttonStyle(.primary)
            .disabled(!viewModel.canContinue(question))
            .opacity(viewModel.canContinue(question) ? 1 : 0.5)
            .padding(Theme.Spacing.lg)
        }
        .onAppear {
            otherText = viewModel.otherText(for: question)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            Text(question.sectionTitle.uppercased())
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.coral)

            Text(question.text)
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.Colors.textDark)

            if let subtitle = question.subtitle {
                Text(subtitle)
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Colors.textMuted)
            }

            selectionHint
        }
    }

    @ViewBuilder
    private var selectionHint: some View {
        switch question.kind {
        case .ranking(let count):
            Text("\(viewModel.selectedCount(for: question)) of \(count) ranked")
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Colors.textMuted)
                .padding(.top, Theme.Spacing.xxs)
        case .multiSelect(let max):
            Text(max.map { "Choose up to \($0)" } ?? "Select all that apply")
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Colors.textMuted)
                .padding(.top, Theme.Spacing.xxs)
        case .singleSelect:
            EmptyView()
        }
    }

    @ViewBuilder
    private var optionsList: some View {
        if case .ranking(let count) = question.kind {
            VStack(spacing: Theme.Spacing.xs) {
                ForEach(question.allOptions) { option in
                    let rank = viewModel.rank(of: option.id, for: question)
                    RankingOptionRow(
                        label: option.label,
                        rank: rank,
                        isDisabled: rank == nil && viewModel.selectedCount(for: question) >= count,
                        onTap: { viewModel.toggle(optionID: option.id, for: question) }
                    )
                }
            }
        } else {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                ForEach(question.groups) { group in
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        if let title = group.title {
                            Text(title)
                                .font(Theme.Typography.headline)
                                .foregroundStyle(Theme.Colors.textDark)
                        }
                        ForEach(group.options) { option in
                            OnboardingOptionRow(
                                label: option.label,
                                isSelected: viewModel.isSelected(option.id, for: question),
                                isDisabled: isOptionDisabled(option),
                                indicatorStyle: indicatorStyle,
                                onTap: { viewModel.toggle(optionID: option.id, for: question) }
                            )
                        }
                    }
                }
            }
        }
    }

    private func isOptionDisabled(_ option: OnboardingOption) -> Bool {
        guard case .multiSelect(let max?) = question.kind else { return false }
        guard !viewModel.isSelected(option.id, for: question) else { return false }
        return viewModel.selectedCount(for: question) >= max
    }

    private var indicatorStyle: OnboardingSelectionIndicatorStyle {
        if case .singleSelect = question.kind { return .checkmarkOnly }
        return .circle
    }

    private var otherTextField: some View {
        TextField("Other (optional)", text: $otherText)
            .font(Theme.Typography.body)
            .focused($isOtherFieldFocused)
            .padding(Theme.Spacing.sm)
            .background(Theme.Colors.creamCard)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .strokeBorder(isOtherFieldFocused ? Theme.Colors.coral : Theme.Colors.border, lineWidth: Theme.Stroke.regular)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .onChange(of: otherText) { _, newValue in
                viewModel.updateOtherText(newValue, for: question)
            }
    }
}
