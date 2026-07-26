//
//  BuildEnvironment.swift
//  Simmr
//

import Foundation

enum BuildEnvironment {
    /// True for a build installed via TestFlight — detected the standard
    /// way, by the filename of the App Store receipt (`sandboxReceipt` for
    /// TestFlight, `receipt` for a production App Store install, no file at
    /// all when run straight from Xcode).
    static var isTestFlight: Bool {
        Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    }

    /// Gates internal debug tooling (currently: shake-to-view API logs).
    /// Enabled for TestFlight so we can debug real tester reports, and for
    /// Xcode/Simulator debug builds so it's actually testable during
    /// development — but never in a production App Store build.
    static var isDebugToolsEnabled: Bool {
        #if DEBUG
        return true
        #else
        return isTestFlight
        #endif
    }
}
