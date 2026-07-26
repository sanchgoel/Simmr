//
//  OpenAIClient.swift
//  Simmr
//
//  Thin, domain-agnostic wrapper around the OpenAI Chat Completions API using
//  Structured Outputs (response_format: json_schema, strict mode). Callers
//  supply a prompt + JSON Schema and get back the raw JSON the model
//  produced; decoding into a concrete Codable type is the caller's job
//  (see RecipeParserService). Keeping this file recipe-agnostic means the
//  same client can power future structured-extraction features.
//

import Foundation

struct OpenAIClient {
    private let apiKey: String
    private let model: String
    private let baseURL: URL
    private let session: URLSession

    init(
        apiKey: String,
        model: String = "gpt-4.1-mini",
        baseURL: URL = URL(string: "https://api.openai.com/v1/chat/completions")!,
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL
        self.session = session
    }

    /// Calls Chat Completions with a Structured Outputs JSON schema and returns the raw JSON
    /// content the model produced, ready to hand to `JSONDecoder`.
    func createStructuredCompletion(
        systemPrompt: String,
        userPrompt: String,
        schemaName: String,
        schema: [String: Any]
    ) async throws -> Data {
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let bodyData = try JSONSerialization.data(withJSONObject: [
            "model": model,
            "temperature": 0.2,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt],
            ],
            "response_format": [
                "type": "json_schema",
                "json_schema": [
                    "name": schemaName,
                    "strict": true,
                    "schema": schema,
                ],
            ],
        ])
        request.httpBody = bodyData

        // Single log point covering every exit path (success or any throw
        // below) — see BuildEnvironment.isDebugToolsEnabled for where this
        // is surfaced (shake-to-view on TestFlight/debug builds only).
        let startedAt = Date()
        var loggedStatusCode: Int?
        var loggedResponseBody: String?
        var loggedError: String?
        defer {
            let entry = APICallLog(
                timestamp: startedAt,
                endpoint: baseURL.lastPathComponent,
                model: model,
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
            let clientError = OpenAIClientError.networkFailure(underlying: error)
            loggedError = clientError.errorDescription
            throw clientError
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            loggedError = OpenAIClientError.invalidResponse.errorDescription
            throw OpenAIClientError.invalidResponse
        }
        loggedStatusCode = httpResponse.statusCode
        loggedResponseBody = String(data: data, encoding: .utf8)

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = (try? JSONDecoder().decode(OpenAIErrorEnvelope.self, from: data))?.error.message
            let clientError = OpenAIClientError.requestFailed(statusCode: httpResponse.statusCode, message: message)
            loggedError = clientError.errorDescription
            throw clientError
        }

        guard let completion = try? JSONDecoder().decode(ChatCompletionResponse.self, from: data) else {
            loggedError = OpenAIClientError.malformedCompletion.errorDescription
            throw OpenAIClientError.malformedCompletion
        }
        guard let content = completion.choices.first?.message.content,
              let contentData = content.data(using: .utf8)
        else {
            loggedError = OpenAIClientError.emptyCompletion.errorDescription
            throw OpenAIClientError.emptyCompletion
        }

        return contentData
    }
}

private struct ChatCompletionResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

private struct OpenAIErrorEnvelope: Decodable {
    struct APIError: Decodable {
        let message: String
    }
    let error: APIError
}

enum OpenAIClientError: LocalizedError {
    case missingAPIKey
    case networkFailure(underlying: Error)
    case invalidResponse
    case requestFailed(statusCode: Int, message: String?)
    case emptyCompletion
    case malformedCompletion

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Add your OpenAI API key in Settings to generate recipes."
        case .networkFailure:
            return "Couldn't reach OpenAI. Check your connection and try again."
        case .invalidResponse:
            return "Received an unexpected response. Please try again."
        case .requestFailed(let statusCode, let message):
            if statusCode == 401 { return "Your OpenAI API key looks invalid. Check it in Settings." }
            if statusCode == 429 { return "Rate limit reached. Please wait a moment and try again." }
            return message ?? "OpenAI request failed (\(statusCode)). Please try again."
        case .emptyCompletion:
            return "The recipe parser returned an empty response. Please try again."
        case .malformedCompletion:
            return "Couldn't read the response from OpenAI. Please try again."
        }
    }
}
