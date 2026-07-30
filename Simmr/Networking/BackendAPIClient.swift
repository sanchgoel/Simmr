//
//  BackendAPIClient.swift
//  Simmr
//
//  Domain-agnostic transport for Simmr's Firebase HTTP API. OpenAI
//  credentials, prompts, model selection, and schema enforcement live only
//  in the backend.
//

import Foundation

struct BackendConfiguration {
    let baseURL: URL
    let apiKey: String

    static func current(
        bundle: Bundle = .main,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) throws -> BackendConfiguration {
        let defaultURL = "https://webapi-bgelt7ybza-uc.a.run.app"
        let baseURLString = environment["SIMMR_BACKEND_BASE_URL"] ?? defaultURL
        guard let baseURL = URL(string: baseURLString) else {
            throw BackendAPIClientError.invalidConfiguration
        }

        if let override = environment["SIMMR_BACKEND_API_KEY"]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !override.isEmpty {
            return BackendConfiguration(baseURL: baseURL, apiKey: override)
        }

        guard let configURL = bundle.url(forResource: "GoogleService-Info", withExtension: "plist"),
              let config = NSDictionary(contentsOf: configURL),
              let apiKey = config["API_KEY"] as? String,
              !apiKey.isEmpty
        else {
            throw BackendAPIClientError.invalidConfiguration
        }

        return BackendConfiguration(baseURL: baseURL, apiKey: apiKey)
    }
}

struct BackendAPIClient {
    private let configuration: BackendConfiguration
    private let apiKey: String
    private let session: URLSession

    init(
        configuration: BackendConfiguration,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.apiKey = configuration.apiKey
        self.session = session
    }

    func post<RequestBody: Encodable, ResponseBody: Decodable>(
        path: String,
        body: RequestBody,
        responseType: ResponseBody.Type = ResponseBody.self
    ) async throws -> ResponseBody {
        let url = configuration.baseURL.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let bodyData = try JSONEncoder().encode(body)
        request.httpBody = bodyData

        let startedAt = Date()
        var loggedStatusCode: Int?
        var loggedResponseBody: String?
        var loggedError: String?
        defer {
            let entry = APICallLog(
                timestamp: startedAt,
                endpoint: url.path,
                model: nil,
                requestBody: String(data: bodyData, encoding: .utf8),
                statusCode: loggedStatusCode,
                responseBody: loggedResponseBody,
                error: loggedError,
                duration: Date().timeIntervalSince(startedAt)
            )
            APIDebugLogStore.shared.log(entry)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            let clientError = BackendAPIClientError.networkFailure(underlying: error)
            loggedError = clientError.errorDescription
            throw clientError
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            loggedError = BackendAPIClientError.invalidResponse.errorDescription
            throw BackendAPIClientError.invalidResponse
        }
        loggedStatusCode = httpResponse.statusCode
        loggedResponseBody = String(data: data, encoding: .utf8)

        guard (200..<300).contains(httpResponse.statusCode) else {
            let error = try? JSONDecoder().decode(BackendErrorEnvelope.self, from: data)
            let clientError = BackendAPIClientError.requestFailed(
                statusCode: httpResponse.statusCode,
                code: error?.error.code,
                message: error?.error.message
            )
            loggedError = clientError.errorDescription
            throw clientError
        }

        do {
            return try JSONDecoder().decode(responseType, from: data)
        } catch {
            loggedError = BackendAPIClientError.malformedResponse.errorDescription
            throw BackendAPIClientError.malformedResponse
        }
    }
}

private struct BackendErrorEnvelope: Decodable {
    struct APIError: Decodable {
        let code: String
        let message: String
    }
    let error: APIError
}

enum BackendAPIClientError: LocalizedError {
    case invalidConfiguration
    case networkFailure(underlying: Error)
    case invalidResponse
    case requestFailed(statusCode: Int, code: String?, message: String?)
    case malformedResponse

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "Simmr's recipe service isn't configured correctly."
        case .networkFailure:
            return "Couldn't reach the recipe service. Check your connection and try again."
        case .invalidResponse:
            return "Received an unexpected response. Please try again."
        case .requestFailed(let statusCode, let code, let message):
            if statusCode == 401 {
                return "Simmr couldn't authenticate with the recipe service."
            }
            if statusCode == 429 || statusCode == 503 || code == "service_busy" {
                return "The recipe service is busy. Please wait a moment and try again."
            }
            return message ?? "Recipe generation failed (\(statusCode)). Please try again."
        case .malformedResponse:
            return "Couldn't read the recipe service response. Please try again."
        }
    }
}
