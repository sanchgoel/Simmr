//
//  ServingsStepper.swift
//  Simmr
//

import SwiftUI

struct ServingsStepper: View {
    @Binding var servings: Int
    var range: ClosedRange<Int> = 1...12

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Text("Servings")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.textDark)

            Spacer()

            HStack(spacing: Theme.Spacing.sm) {
                stepperButton(systemImage: "minus", action: decrement, isEnabled: servings > range.lowerBound)

                Text("\(servings)")
                    .font(Theme.Typography.title3)
                    .foregroundStyle(Theme.Colors.textDark)
                    .frame(minWidth: 28)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: servings)

                stepperButton(systemImage: "plus", action: increment, isEnabled: servings < range.upperBound)
            }
        }
    }

    private func stepperButton(systemImage: String, action: @escaping () -> Void, isEnabled: Bool) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isEnabled ? Theme.Colors.textDark : Theme.Colors.textMuted)
                .frame(width: 32, height: 32)
                .background(Theme.Colors.creamCard)
                .overlay(
                    Circle().strokeBorder(Theme.Colors.border, lineWidth: Theme.Stroke.hairline)
                )
                .clipShape(Circle())
        }
        .disabled(!isEnabled)
    }

    private func increment() {
        guard servings < range.upperBound else { return }
        servings += 1
    }

    private func decrement() {
        guard servings > range.lowerBound else { return }
        servings -= 1
    }
}

#Preview {
    ServingsStepper(servings: .constant(4))
        .padding()
        .background(Theme.Colors.creamBackground)
}
