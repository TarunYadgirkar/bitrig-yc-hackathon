// ClaudeService.swift
import Foundation

struct ClaudeService {
    static let apiKey = "YOUR_CLAUDE_API_KEY"
    static let endpoint = "https://api.anthropic.com/v1/messages"

    static func generateAppIntents(for appDescription: String) async throws -> String {
        let requestBody: [String: Any] = [
            "model": "claude-sonnet-4-6",
            "max_tokens": 2000,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": "Generate App Intents for this iOS app: \(appDescription)"]
            ]
        ]

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        return response.content.first?.text ?? "Error: No response"
    }
}

struct ClaudeResponse: Codable {
    let content: [ContentBlock]

    struct ContentBlock: Codable {
        let text: String
        let type: String
    }
}
