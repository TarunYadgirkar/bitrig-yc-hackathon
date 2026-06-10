// ClaudeService.swift
import Foundation

// MARK: - Configuration

private enum Config {
    // Key lives in Secrets.swift (gitignored). See Secrets.swift.example.
    static let apiKey = Secrets.anthropicAPIKey
    static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    static let model = "claude-opus-4-8"
    static let maxTokens = 2000
    static let timeoutSeconds: TimeInterval = 120
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

        return try await streamText(requestBody: [
            "model": Config.model,
            "max_tokens": Config.maxTokens,
            "stream": true,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": "Generate App Intents for this iOS app: \(trimmed)"]
            ]
        ])
    }

    // MARK: - Streaming transport
    //
    // We stream the response (Server-Sent Events) rather than waiting for the
    // whole body. App Intents generations take 10–20s; a non-streaming request
    // sits idle that whole time and iOS tears the socket down with
    // "The network connection was lost" (URLError -1005). Streaming keeps bytes
    // flowing continuously, so the connection stays alive — and it feels faster.
    private static func streamText(requestBody: [String: Any]) async throws -> String {
        var request = URLRequest(url: Config.endpoint, timeoutInterval: Config.timeoutSeconds)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Config.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(Config.anthropicVersion, forHTTPHeaderField: "anthropic-version")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw ClaudeError.decodingFailed("Could not serialize request body.")
        }

        let bytes: URLSession.AsyncBytes
        let response: URLResponse
        do {
            (bytes, response) = try await URLSession.shared.bytes(for: request)
        } catch let urlError as URLError where urlError.code == .timedOut {
            throw ClaudeError.timeout
        }

        guard let http = response as? HTTPURLResponse else {
            throw ClaudeError.invalidResponse
        }

        // Non-2xx: drain the (small, non-streamed) error body and surface it.
        guard (200...299).contains(http.statusCode) else {
            var raw = ""
            for try await line in bytes.lines { raw += line }
            let message: String
            if let data = raw.data(using: .utf8),
               let decoded = try? JSONDecoder().decode(ClaudeErrorResponse.self, from: data) {
                message = decoded.error.message
            } else {
                message = HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
            }
            throw ClaudeError.httpError(statusCode: http.statusCode, message: message)
        }

        // Parse the SSE stream, accumulating text deltas into the full response.
        var text = ""
        for try await line in bytes.lines {
            guard line.hasPrefix("data:") else { continue }
            let payload = line.dropFirst("data:".count).trimmingCharacters(in: .whitespaces)
            guard !payload.isEmpty, payload != "[DONE]",
                  let data = payload.data(using: .utf8),
                  let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let type = event["type"] as? String else { continue }

            switch type {
            case "content_block_delta":
                if let delta = event["delta"] as? [String: Any],
                   let chunk = delta["text"] as? String {
                    text += chunk
                }
            case "error":
                let message = (event["error"] as? [String: Any])?["message"] as? String
                    ?? "The stream returned an error."
                throw ClaudeError.httpError(statusCode: http.statusCode, message: message)
            default:
                continue
            }
        }

        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ClaudeError.emptyContent
        }
        return text
    }
}

// MARK: - Fix Mode

extension ClaudeService {
    static func fixAppIntents(originalCode: String, issue: String) async throws -> String {
        return try await streamText(requestBody: [
            "model": Config.model,
            "max_tokens": Config.maxTokens,
            "stream": true,
            "system": fixPrompt,
            "messages": [
                [
                    "role": "user",
                    "content": """
                    Existing App Intents implementation:
                    \(originalCode)

                    What went wrong when Siri tried to use it:
                    \(issue)
                    """
                ]
            ]
        ])
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
