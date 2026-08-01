//
//  SimmrApp.swift
//  Simmr
//
//  Created by Ajay Mann on 12/07/26.
//

import GoogleSignIn
import SwiftUI

@main
struct SimmrApp: App {
    init() {
        AppFonts.register()
        // Configures Firebase (if GoogleService-Info.plist is present) as
        // early as possible, before any other Firebase API gets touched.
        _ = AuthenticationManager.shared
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
                // Two sources of incoming URLs: our own `simmr://` deep
                // links (currently just the finished Live Activity's "Rate
                // it" button — see DeepLinkRouter) and GoogleSignIn's iOS
                // flow, which redirects back via a custom URL scheme
                // (REVERSED_CLIENT_ID) to complete the sign-in.
                .onOpenURL { url in
                    if !DeepLinkRouter.shared.handle(url) {
                        GIDSignIn.sharedInstance.handle(url)
                    }
                }
        }
    }
}
