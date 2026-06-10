// ClaudeService.swift
import Foundation

// MARK: - Configuration

private enum Config {
    // ⚠️ Replace with your Claude Max API key before running. Do NOT commit a real key.
    static let apiKey = "YOUR_CLAUDE_API_KEY"
    static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    // claude-sonnet-4-5 is deprecated — use claude-sonnet-4-6
    static let model = "claude-sonnet-4-6"
    static let maxTokens = 2000
    static let timeoutSeconds: TimeInterval = 60
    static let anthropicVersion = "2023-06-01"
}

// MARK: - Error Types

enum ClaudeError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case emptyContent
    case decodingFailed(String)
    case timeout

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Couldn't reach the Claude API. Check your internet connection."
        case .httpError(let code, let message):
            return "API error \(code): \(message)"
        case .emptyContent:
            return "Claude returned an empty response. Try a more detailed app description."
        case .decodingFailed(let detail):
            return "Couldn't parse the API response: \(detail)"
        case .timeout:
            return "The request timed out. Check your connection and try again."
        }
    }
}

// MARK: - Response Models

private struct ClaudeResponse: Decodable {
    let content: [ContentBlock]
    let stopReason: String?

    enum CodingKeys: String, CodingKey {
        case content
        case stopReason = "stop_reason"
    }

    struct ContentBlock: Decodable {
        let type: String
        let text: String?
    }
}

private struct ClaudeErrorResponse: Decodable {
    let error: ClaudeAPIError

    struct ClaudeAPIError: Decodable {
        let type: String
        let message: String
    }
}

// MARK: - Service

struct ClaudeService {

    static func generateAppIntents(for appDescription: String) async throws -> String {
        let trimmed = appDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ClaudeError.emptyContent
        }

        let requestBody: [String: Any] = [
            "model": Config.model,
            "max_tokens": Config.maxTokens,
            "system": systemPrompt,
            "messages": [
                [
                    "role": "user",
                    "content": "Generate App Intents for this iOS app: \(trimmed)"
                ]
            ]
        ]

        var request = URLRequest(
            url: Config.endpoint,
            timeoutInterval: Config.timeoutSeconds
        )
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Config.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(Config.anthropicVersion, forHTTPHeaderField: "anthropic-version")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw ClaudeError.decodingFailed("Could not serialize request body.")
        }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let urlError as URLError where urlError.code == .timedOut {
            throw ClaudeError.timeout
        }

        guard let http = response as? HTTPURLResponse else {
            throw ClaudeError.invalidResponse
        }

        // Handle non-2xx HTTP status codes
        guard (200...299).contains(http.statusCode) else {
            let errorMessage: String
            if let errorResponse = try? JSONDecoder().decode(ClaudeErrorResponse.self, from: data) {
                errorMessage = errorResponse.error.message
            } else {
                errorMessage = HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
            }
            throw ClaudeError.httpError(statusCode: http.statusCode, message: errorMessage)
        }

        let decoded: ClaudeResponse
        do {
            decoded = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        } catch {
            throw ClaudeError.decodingFailed(error.localizedDescription)
        }

        guard let text = decoded.content.first(where: { $0.type == "text" })?.text,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ClaudeError.emptyContent
        }

        return text
    }
}

// MARK: - Offline Fallback
// If there's no WiFi at the venue, swap ClaudeService.generateAppIntents() for this:
// (Uncomment, test one description, hardcode the known-good output as cachedOutput)

/*
extension ClaudeService {
    static func generateAppIntentsFallback(for appDescription: String) async throws -> String {
        let cachedOutput = """
        import Foundation
        import AppIntents

        // Paste your pre-tested output here
        """
        return cachedOutput
    }
}
*/
