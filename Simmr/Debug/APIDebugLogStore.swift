//
//  APIDebugLogStore.swift
//  Simmr
//
//  In-memory only (never persisted — these are raw request/response bodies,
//  no reason to write them to disk). Capped so a long TestFlight session
//  can't grow this unbounded.
//

import Combine
import Foundation

@MainActor
final class APIDebugLogStore: ObservableObject {
    static let shared = APIDebugLogStore()

    @Published private(set) var logs: [APICallLog] = []
    private let maxLogs = 50

    private init() {}

    func log(_ entry: APICallLog) {
        logs.insert(entry, at: 0)
        if logs.count > maxLogs {
            logs.removeLast(logs.count - maxLogs)
        }
    }

    func clear() {
        logs.removeAll()
    }
}
