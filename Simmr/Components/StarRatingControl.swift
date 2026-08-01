//
//  StarRatingControl.swift
//  Simmr
//
//  Reusable 5-star tap-to-rate control. `rating` is nil until the user
//  taps a star — Screen 1's Continue button stays disabled on nil so
//  there's no accidental default rating.
//

import SwiftUI

struct StarRatingControl: View {
    @Binding var rating: Int?
    var starSize: CGFloat = 40

    @State private var bouncingStar: Int?

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: isFilled(star) ? "star.fill" : "star")
                    .font(.system(size: starSize))
                    .foregroundStyle(isFilled(star) ? Theme.Colors.coral : Theme.Colors.border)
                    .scaleEffect(bouncingStar == star ? 1.2 : 1)
                    .onTapGesture { select(star) }
                    .accessibilityLabel("\(star) star\(star == 1 ? "" : "s")")
                    .accessibilityAddTraits(isFilled(star) ? .isSelected : [])
            }
        }
    }

    private func isFilled(_ star: Int) -> Bool {
        guard let rating else { return false }
        return star <= rating
    }

    private func select(_ star: Int) {
        rating = star
        withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
            bouncingStar = star
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
                bouncingStar = nil
            }
        }
    }
}

#Preview {
    StarRatingControl(rating: .constant(4))
        .padding()
        .background(Theme.Colors.creamBackground)
}
