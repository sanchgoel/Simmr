//
//  Theme+Colors.swift
//  Simmr
//
//  Theme color tokens, defined directly from the design spec's hex values.
//

import SwiftUI

enum Theme {
    enum Colors {
        /// Primary — CTAs, selections, icons.
        static let coral = Color(hex: "#FF5A36")
        /// Secondary accent — use sparingly.
        static let amber = Color(hex: "#FFB03B")
        /// Screen background.
        static let creamBackground = Color(hex: "#FFFDF8")
        /// Cards, tiles.
        static let creamCard = Color(hex: "#FFF9F0")
        /// Headings, body text.
        static let textDark = Color(hex: "#241B14")
        /// Subtitles, captions.
        static let textMuted = Color(hex: "#9C8E7C")
        /// Dividers, unselected states.
        static let border = Color(hex: "#EDE3CF")
        /// Selected-state background wash.
        static let tint = Color(hex: "#FFF1EC")
    }
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
