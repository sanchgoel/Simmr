//
//  OnboardingOption.swift
//  Simmr
//

import Foundation

struct OnboardingOption: Identifiable, Hashable {
    let id: String
    let label: String
    /// Selecting this option clears every other option in the same question
    /// (e.g. "None of these", "No preference"), and vice versa.
    var isExclusive: Bool = false
}

struct OnboardingOptionGroup: Identifiable, Hashable {
    let id: String
    /// Nil for a flat (ungrouped) option list — no section header is rendered.
    let title: String?
    let options: [OnboardingOption]
}
