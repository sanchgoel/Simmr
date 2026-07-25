//
//  CookingSessionRepository.swift
//  Simmr
//
//  Unlike the rest of Storage/'s <Domain>Storing/UserDefaults<Domain>Store
//  pair, this is deliberately named "Repository" and declared async throws
//  even though LocalCookingSessionRepository's actual work is synchronous
//  UserDefaults I/O — Firestore/Firebase APIs are inherently async throws,
//  so a future FirebaseCookingSessionRepository can swap in here with zero
//  call-site changes anywhere else in the app.
//

import Foundation

protocol CookingSessionRepository {
    /// All sessions, sorted by updatedAt descending.
    func fetchAllSessions() async throws -> [CookingSession]
    /// The single in-progress session, if any. Status == .active only —
    /// this is the launch-restore signal, not a general "resumable" query.
    func fetchActiveSession() async throws -> CookingSession?
    /// Upserts by id.
    func save(_ session: CookingSession) async throws
    /// Removes a session by id — a no-op if it's already gone.
    func delete(id: UUID) async throws
}

final class LocalCookingSessionRepository: CookingSessionRepository {
    /// Completed or never-started sessions beyond this many (oldest first,
    /// each bucket capped independently) are dropped on save —
    /// CookingSession.recipe embeds the full recipe text, so an unbounded
    /// blob would eventually stutter the UI thread since it's re-encoded in
    /// full on every single step/timer tap while cooking. Active/paused
    /// sessions are never dropped.
    private static let maxInactiveSessionsPerStatus = 50

    private let key = "com.inspiredevstudio.Simmr.cookingSessions"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func fetchAllSessions() async throws -> [CookingSession] {
        loadAll().sorted { $0.updatedAt > $1.updatedAt }
    }

    func fetchActiveSession() async throws -> CookingSession? {
        loadAll().first { $0.status == .active }
    }

    func save(_ session: CookingSession) async throws {
        var all = loadAll()
        if let index = all.firstIndex(where: { $0.id == session.id }) {
            all[index] = session
        } else {
            all.append(session)
        }
        all = capInactiveSessions(all)

        guard let data = try? JSONEncoder().encode(all) else { return }
        defaults.set(data, forKey: key)
    }

    func delete(id: UUID) async throws {
        let all = loadAll().filter { $0.id != id }
        guard let data = try? JSONEncoder().encode(all) else { return }
        defaults.set(data, forKey: key)
    }

    /// Decodes element-by-element with per-element try? rather than one
    /// decode([CookingSession].self, ...) call, so a single malformed row
    /// (e.g. from a future schema change) can't silently wipe all history.
    private func loadAll() -> [CookingSession] {
        guard let data = defaults.data(forKey: key),
              let rawArray = try? JSONSerialization.jsonObject(with: data) as? [Any]
        else { return [] }

        let decoder = JSONDecoder()
        return rawArray.compactMap { element in
            guard let elementData = try? JSONSerialization.data(withJSONObject: element) else { return nil }
            return try? decoder.decode(CookingSession.self, from: elementData)
        }
    }

    private func capInactiveSessions(_ sessions: [CookingSession]) -> [CookingSession] {
        let live = sessions.filter { $0.status == .active || $0.status == .paused }
        let capped: (CookingSessionStatus) -> [CookingSession] = { status in
            sessions
                .filter { $0.status == status }
                .sorted { $0.updatedAt > $1.updatedAt }
                .prefix(Self.maxInactiveSessionsPerStatus)
                .map { $0 }
        }
        return live + capped(.completed) + capped(.notStarted)
    }
}
