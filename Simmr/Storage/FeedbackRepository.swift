//
//  FeedbackRepository.swift
//  Simmr
//
//  Mirrors CookingSessionRepository's own rationale: declared async throws
//  even though LocalFeedbackRepository's actual work is synchronous
//  UserDefaults I/O, so a future FirebaseFeedbackRepository can swap in
//  here with zero call-site changes anywhere else in the app.
//

import Foundation

protocol FeedbackRepository {
    /// All records, sorted by createdAt descending.
    func fetchAll() async throws -> [FeedbackRecord]
    /// Upserts by id.
    func save(_ record: FeedbackRecord) async throws
}

final class LocalFeedbackRepository: FeedbackRepository {
    private let key = "com.inspiredevstudio.Simmr.feedbackRecords"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func fetchAll() async throws -> [FeedbackRecord] {
        loadAll().sorted { $0.createdAt > $1.createdAt }
    }

    func save(_ record: FeedbackRecord) async throws {
        var all = loadAll()
        if let index = all.firstIndex(where: { $0.id == record.id }) {
            all[index] = record
        } else {
            all.append(record)
        }

        let data = try JSONEncoder().encode(all)
        defaults.set(data, forKey: key)
        await FirestoreSyncManager.shared.syncFeedback(record)
    }

    /// Decodes element-by-element with per-element try? rather than one
    /// decode([FeedbackRecord].self, ...) call, so a single malformed row
    /// (e.g. from a future schema change) can't silently wipe all history —
    /// same approach as LocalCookingSessionRepository.loadAll().
    private func loadAll() -> [FeedbackRecord] {
        guard let data = defaults.data(forKey: key),
              let rawArray = try? JSONSerialization.jsonObject(with: data) as? [Any]
        else { return [] }

        let decoder = JSONDecoder()
        return rawArray.compactMap { element in
            guard let elementData = try? JSONSerialization.data(withJSONObject: element) else { return nil }
            return try? decoder.decode(FeedbackRecord.self, from: elementData)
        }
    }
}
