//
//  OnboardingQuestion.swift
//  Simmr
//
//  Data-driven question definition so the onboarding flow renders every
//  question (single-select, capped multi-select, grouped multi-select,
//  ranking) through one generic view instead of one-off screens per question.
//

import Foundation

enum OnboardingQuestionKind {
    case singleSelect
    /// `maxSelections` nil means unlimited.
    case multiSelect(maxSelections: Int?)
    /// User ranks exactly `count` options in priority order.
    case ranking(count: Int)
}

struct OnboardingQuestion: Identifiable {
    let id: String
    let sectionTitle: String
    let text: String
    let subtitle: String?
    let kind: OnboardingQuestionKind
    let groups: [OnboardingOptionGroup]
    let allowsOtherText: Bool
    /// Whether this question should appear in the flow, evaluated against answers so far.
    /// Used for conditional follow-ups (e.g. allergies only shown if the user flagged allergies).
    let isVisible: (OnboardingAnswers) -> Bool

    init(
        id: String,
        sectionTitle: String,
        text: String,
        subtitle: String? = nil,
        kind: OnboardingQuestionKind,
        groups: [OnboardingOptionGroup],
        allowsOtherText: Bool = false,
        isVisible: @escaping (OnboardingAnswers) -> Bool = { _ in true }
    ) {
        self.id = id
        self.sectionTitle = sectionTitle
        self.text = text
        self.subtitle = subtitle
        self.kind = kind
        self.groups = groups
        self.allowsOtherText = allowsOtherText
        self.isVisible = isVisible
    }

    /// Convenience initializer for the common case of one flat, ungrouped option list.
    init(
        id: String,
        sectionTitle: String,
        text: String,
        subtitle: String? = nil,
        kind: OnboardingQuestionKind,
        options: [OnboardingOption],
        allowsOtherText: Bool = false,
        isVisible: @escaping (OnboardingAnswers) -> Bool = { _ in true }
    ) {
        self.init(
            id: id,
            sectionTitle: sectionTitle,
            text: text,
            subtitle: subtitle,
            kind: kind,
            groups: [OnboardingOptionGroup(id: id, title: nil, options: options)],
            allowsOtherText: allowsOtherText,
            isVisible: isVisible
        )
    }

    var allOptions: [OnboardingOption] { groups.flatMap(\.options) }
}
