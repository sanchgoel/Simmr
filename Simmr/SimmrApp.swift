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
        }
    }
}
