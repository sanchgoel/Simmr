//
//  SimmrApp.swift
//  Simmr
//
//  Created by Ajay Mann on 12/07/26.
//

import SwiftUI

@main
struct SimmrApp: App {
    init() {
        AppFonts.register()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                // The app is light-mode-only by design — forcing this here
                // (rather than relying on system Dark Mode following our
                // light colors by coincidence) also fixes the status bar,
                // which otherwise renders light-content-on-light-background
                // and becomes invisible when the system is in Dark Mode.
                .preferredColorScheme(.light)
        }
    }
}
