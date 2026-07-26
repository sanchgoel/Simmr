//
//  ShakeDetector.swift
//  Simmr
//
//  Lets a SwiftUI-only app (no AppDelegate/SceneDelegate) react to the
//  device-shake motion gesture: UIWindow already inherits `motionEnded`
//  from UIResponder as an `@objc dynamic` method, so overriding it from an
//  extension works via the Objective-C runtime even though Swift normally
//  disallows overriding in extensions.
//

import SwiftUI
import UIKit

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: .deviceDidShake, object: nil)
        }
        super.motionEnded(motion, with: event)
    }
}

extension Notification.Name {
    static let deviceDidShake = Notification.Name("com.inspiredevstudio.simmr.deviceDidShake")
}

extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in
            action()
        }
    }
}
