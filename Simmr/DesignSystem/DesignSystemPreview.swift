//
//  DesignSystemPreview.swift
//  Simmr
//
//  Living style guide: renders every color, type style, and spacing token
//  so the design language can be sanity-checked on-device.
//

import SwiftUI

struct DesignSystemPreview: View {
    @State private var selectedChip = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                header
                colorSection
                typographySection
                spacingSection
                componentSection
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Colors.creamBackground.ignoresSafeArea())
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            Text("Simmr Design Language")
                .font(Theme.Typography.largeTitle)
                .foregroundStyle(Theme.Colors.textDark)
            Text("Rethink Sans · Color · Spacing")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.textMuted)
        }
    }

    // MARK: Colors

    private var colorSection: some View {
        SectionContainer(title: "Colors") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: Theme.Spacing.sm)], spacing: Theme.Spacing.sm) {
                ColorSwatch(name: "Coral", hex: "#FF5A36", color: Theme.Colors.coral, lightText: true)
                ColorSwatch(name: "Amber", hex: "#FFB03B", color: Theme.Colors.amber, lightText: true)
                ColorSwatch(name: "Cream BG", hex: "#FFFDF8", color: Theme.Colors.creamBackground, lightText: false)
                ColorSwatch(name: "Cream Card", hex: "#FFF9F0", color: Theme.Colors.creamCard, lightText: false)
                ColorSwatch(name: "Text Dark", hex: "#241B14", color: Theme.Colors.textDark, lightText: true)
                ColorSwatch(name: "Text Muted", hex: "#9C8E7C", color: Theme.Colors.textMuted, lightText: true)
                ColorSwatch(name: "Border", hex: "#EDE3CF", color: Theme.Colors.border, lightText: false)
                ColorSwatch(name: "Tint", hex: "#FFF1EC", color: Theme.Colors.tint, lightText: false)
            }
        }
    }

    // MARK: Typography

    private var typographySection: some View {
        SectionContainer(title: "Typography") {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                TypeSample(label: "Large Title / ExtraBold 34", font: Theme.Typography.largeTitle)
                TypeSample(label: "Title / Bold 28", font: Theme.Typography.title)
                TypeSample(label: "Title 2 / SemiBold 22", font: Theme.Typography.title2)
                TypeSample(label: "Headline / SemiBold 17", font: Theme.Typography.headline)
                TypeSample(label: "Body / Regular 17", font: Theme.Typography.body)
                TypeSample(label: "Callout / Medium 16", font: Theme.Typography.callout)
                TypeSample(label: "Subheadline / Regular 15", font: Theme.Typography.subheadline)
                TypeSample(label: "Footnote / Regular 13", font: Theme.Typography.footnote)
                TypeSample(label: "Caption / Medium 12", font: Theme.Typography.caption)
            }
        }
    }

    // MARK: Spacing

    private var spacingSection: some View {
        SectionContainer(title: "Spacing") {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                SpacingBar(label: "xxs", value: Theme.Spacing.xxs)
                SpacingBar(label: "xs", value: Theme.Spacing.xs)
                SpacingBar(label: "sm", value: Theme.Spacing.sm)
                SpacingBar(label: "md", value: Theme.Spacing.md)
                SpacingBar(label: "lg", value: Theme.Spacing.lg)
                SpacingBar(label: "xl", value: Theme.Spacing.xl)
                SpacingBar(label: "xxl", value: Theme.Spacing.xxl)
            }
        }
    }

    // MARK: Components

    private var componentSection: some View {
        SectionContainer(title: "Components") {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Button("Primary CTA") {}
                    .buttonStyle(.primary)
                Button("Secondary Action") {}
                    .buttonStyle(.secondary)

                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text("Card Title")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.textDark)
                    Text("Cards sit on creamCard with a hairline border and a large radius.")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.textMuted)
                }
                .padding(Theme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()

                HStack(spacing: Theme.Spacing.xs) {
                    ForEach(0..<3) { index in
                        Text("Option \(index + 1)")
                            .font(Theme.Typography.callout)
                            .foregroundStyle(Theme.Colors.textDark)
                            .padding(.vertical, Theme.Spacing.xs)
                            .padding(.horizontal, Theme.Spacing.sm)
                            .selectionTint(isSelected: selectedChip == index)
                            .onTapGesture { selectedChip = index }
                    }
                }
            }
        }
    }
}

// MARK: - Building blocks used only by this preview

private struct SectionContainer<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(title)
                .font(Theme.Typography.title3)
                .foregroundStyle(Theme.Colors.textDark)
            content
        }
    }
}

private struct ColorSwatch: View {
    let name: String
    let hex: String
    let color: Color
    let lightText: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
            Text(name)
                .font(Theme.Typography.caption)
                .foregroundStyle(lightText ? .white : Theme.Colors.textDark)
            Text(hex)
                .font(Theme.Typography.caption2)
                .foregroundStyle(lightText ? .white.opacity(0.8) : Theme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.sm)
        .frame(height: 72)
        .background(color)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                .strokeBorder(Theme.Colors.border, lineWidth: Theme.Stroke.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
    }
}

private struct TypeSample: View {
    let label: String
    let font: Font

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Simmr — Rethink Sans")
                .font(font)
                .foregroundStyle(Theme.Colors.textDark)
            Text(label)
                .font(Theme.Typography.caption2)
                .foregroundStyle(Theme.Colors.textMuted)
        }
    }
}

private struct SpacingBar: View {
    let label: String
    let value: CGFloat

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textMuted)
                .frame(width: 32, alignment: .leading)
            RoundedRectangle(cornerRadius: Theme.Radius.sm / 2, style: .continuous)
                .fill(Theme.Colors.coral)
                .frame(width: value * 3, height: 12)
            Text("\(Int(value))pt")
                .font(Theme.Typography.caption2)
                .foregroundStyle(Theme.Colors.textMuted)
        }
    }
}

#Preview {
    DesignSystemPreview()
}
