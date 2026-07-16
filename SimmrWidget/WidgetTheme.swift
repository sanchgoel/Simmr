//
//  WidgetTheme.swift
//  SimmrWidget
//
//  A handful of the app's brand colors, duplicated as literal/asset-catalog
//  values rather than sharing Simmr/DesignSystem — the widget extension is
//  a separate process/binary, and pulling in the whole design system (plus
//  re-registering the app's custom Rethink Sans font at runtime, which
//  only happens in the main app process) isn't worth it for a small,
//  glanceable UI where system fonts are the more legible choice anyway.
//
//  Unlike the rest of the app (light mode only), the Lock Screen
//  presentation adapts to dark mode. Background/text tokens are Assets.xcassets
//  color sets with Any + Dark appearances — reading `@Environment(\.colorScheme)`
//  directly proved unreliable inside ActivityKit's Lock Screen rendering
//  pass, whereas asset-catalog dynamic colors are the mechanism Apple's own
//  widgets use and resolve correctly there. The Dynamic Island always
//  renders against a physically black cutout regardless of system
//  appearance, so those views intentionally use the "dark" literal colors
//  below rather than these adaptive tokens.
//

import SwiftUI

/// `Bundle.main` doesn't reliably resolve to this extension's own bundle
/// inside ActivityKit's Lock Screen rendering process — this marker class
/// pins the lookup to the bundle that actually contains Assets.car.
private final class BundleMarker {}

enum WidgetTheme {
    private static let bundle = Bundle(for: BundleMarker.self)

    static let coral = Color(hex: "#FF5A36")

    static let creamBackground = Color("WidgetBackground", bundle: bundle)
    static let textDark = Color("WidgetTextPrimary", bundle: bundle)
    static let textMuted = Color("WidgetTextMuted", bundle: bundle)

    /// Fixed dark-style tokens for the Dynamic Island, which is always a
    /// black cutout regardless of the system's light/dark setting.
    static let islandTextPrimary = Color(hex: "#F6F1E9")
    static let islandTextMuted = Color(hex: "#B3A793")
}

extension Color {
    init(hex: String) {
        let hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&value)

        self.init(
            .sRGB,
            red: Double((value & 0xFF0000) >> 16) / 255,
            green: Double((value & 0x00FF00) >> 8) / 255,
            blue: Double(value & 0x0000FF) / 255,
            opacity: 1
        )
    }
}
