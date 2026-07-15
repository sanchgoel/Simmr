//
//  KitchenProfile.swift
//  Simmr
//
//  Persisted onboarding result. Kept as a raw answers dictionary rather than
//  a bespoke strongly-typed profile — the feature that actually consumes
//  this (personalized recipe generation) doesn't exist yet, so mapping it
//  into a domain model now would be guessing at a shape we don't need yet.
//

import Foundation

struct KitchenProfile: Codable, Equatable {
    var answers: OnboardingAnswers
    var isComplete: Bool
    var completedAt: Date?
}
