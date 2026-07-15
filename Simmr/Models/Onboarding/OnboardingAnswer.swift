//
//  OnboardingAnswer.swift
//  Simmr
//

import Foundation

struct OnboardingAnswer: Codable, Equatable {
    /// Selected option ids. For ranking questions, order encodes rank (index 0 = rank 1).
    var selectedOptionIDs: [String] = []
    var otherText: String = ""
}

/// Answers keyed by OnboardingQuestion.id.
typealias OnboardingAnswers = [String: OnboardingAnswer]
