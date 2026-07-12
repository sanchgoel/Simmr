//
//  Theme+Typography.swift
//  Simmr
//
//  Typography scale built on Rethink Sans. Sizes use Font.custom(relativeTo:)
//  so text still scales with Dynamic Type.
//

import SwiftUI

extension Theme {
    enum Typography {
        /// Registered PostScript names for each embedded Rethink Sans weight.
        /// See AppFonts.register() for where these get loaded into the system.
        enum FontName {
            static let regular = "RethinkSans-Regular"
            static let medium = "RethinkSans-Medium"
            static let semiBold = "RethinkSans-SemiBold"
            static let bold = "RethinkSans-Bold"
            static let extraBold = "RethinkSans-ExtraBold"
            static let italic = "RethinkSans-Italic"
        }

        static let largeTitle = Font.custom(FontName.extraBold, size: 34, relativeTo: .largeTitle)
        static let title = Font.custom(FontName.bold, size: 28, relativeTo: .title)
        static let title2 = Font.custom(FontName.semiBold, size: 22, relativeTo: .title2)
        static let title3 = Font.custom(FontName.semiBold, size: 20, relativeTo: .title3)
        static let headline = Font.custom(FontName.semiBold, size: 17, relativeTo: .headline)
        static let body = Font.custom(FontName.regular, size: 17, relativeTo: .body)
        static let bodyMedium = Font.custom(FontName.medium, size: 17, relativeTo: .body)
        static let callout = Font.custom(FontName.medium, size: 16, relativeTo: .callout)
        static let subheadline = Font.custom(FontName.regular, size: 15, relativeTo: .subheadline)
        static let footnote = Font.custom(FontName.regular, size: 14, relativeTo: .footnote)
        static let caption = Font.custom(FontName.medium, size: 12, relativeTo: .caption)
        static let caption2 = Font.custom(FontName.regular, size: 11, relativeTo: .caption2)
        /// Button label style.
        static let button = Font.custom(FontName.semiBold, size: 17, relativeTo: .body)

        /// Large, readable step title for Cooking Mode.
        static let cookingStepTitle = Font.custom(FontName.bold, size: 30, relativeTo: .title)
        /// Large, readable step instruction body for Cooking Mode.
        static let cookingInstruction = Font.custom(FontName.medium, size: 22, relativeTo: .title3)
        /// Large monospaced-feel timer readout.
        static let timerDisplay = Font.custom(FontName.extraBold, size: 44, relativeTo: .largeTitle)
    }
}
