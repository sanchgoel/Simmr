//
//  FeedbackTextField.swift
//  Simmr
//
//  Reusable optional multiline text input with placeholder + helper text —
//  used by the negative flow's detail screen to let someone add a bit more
//  context after picking a structured reason, without ever requiring it.
//

import SwiftUI

struct FeedbackTextField: View {
    @Binding var text: String
    let placeholder: String
    let helperText: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textMuted)
                        .padding(.horizontal, Theme.Spacing.sm + 4)
                        .padding(.vertical, Theme.Spacing.sm + 4)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $text)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textDark)
                    .scrollContentBackground(.hidden)
                    .padding(Theme.Spacing.xs)
                    .frame(minHeight: 100)
            }
            .background(Theme.Colors.creamCard)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .strokeBorder(Theme.Colors.border, lineWidth: Theme.Stroke.regular)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))

            Text(helperText)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textMuted)
        }
    }
}

#Preview {
    FeedbackTextField(
        text: .constant(""),
        placeholder: "Anything else you'd like to explain?",
        helperText: "Totally optional."
    )
    .padding()
    .background(Theme.Colors.creamBackground)
}
