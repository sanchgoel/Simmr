//
//  AppFonts.swift
//  Simmr
//
//  Registers the bundled Rethink Sans font files with Core Text at launch.
//  Runtime registration (rather than an Info.plist UIAppFonts entry) works
//  identically across every platform this target ships to (iOS, macOS, visionOS).
//

import CoreText
import Foundation

enum AppFonts {
    private static let fileNames = [
        Theme.Typography.FontName.regular,
        Theme.Typography.FontName.medium,
        Theme.Typography.FontName.semiBold,
        Theme.Typography.FontName.bold,
        Theme.Typography.FontName.extraBold,
        Theme.Typography.FontName.italic,
    ]

    private static var didRegister = false

    /// Call once, as early as possible (e.g. from the App's init).
    static func register() {
        guard !didRegister else { return }
        didRegister = true

        for name in fileNames {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf")
                ?? Bundle.main.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts")
            else {
                assertionFailure("Missing bundled font file: \(name).ttf")
                continue
            }

            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error), let error {
                let cfError = error.takeRetainedValue()
                // Ignore "already registered" — harmless if register() somehow runs twice.
                if (cfError as Error) is CFError,
                   CFErrorGetCode(cfError) != CTFontManagerError.alreadyRegistered.rawValue {
                    print("Failed to register font \(name): \(cfError)")
                }
            }
        }
    }
}
