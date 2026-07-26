//
//  APICallLog.swift
//  Simmr
//

import Foundation

struct APICallLog: Identifiable {
    let id = UUID()
    let timestamp: Date
    let endpoint: String
    let model: String?
    let requestBody: String?
    let statusCode: Int?
    let responseBody: String?
    let error: String?
    let duration: TimeInterval

    var isSuccess: Bool { error == nil }
}
