//
//  KitchenProfileStore.swift
//  Simmr
//

import Foundation

protocol KitchenProfileStoring {
    func load() -> KitchenProfile?
    func save(_ profile: KitchenProfile)
    func clear()
}

final class UserDefaultsKitchenProfileStore: KitchenProfileStoring {
    private let key = "com.inspiredevstudio.Simmr.kitchenProfile"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> KitchenProfile? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(KitchenProfile.self, from: data)
    }

    func save(_ profile: KitchenProfile) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        defaults.set(data, forKey: key)
        Task { await FirestoreSyncManager.shared.syncKitchenProfile(profile) }
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}
