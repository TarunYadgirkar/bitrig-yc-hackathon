// GenerationState.swift
import SwiftUI

enum GenerationState {
    case idle
    case loading
    case success(code: String)
    case error(message: String)
}

@MainActor
class IntentViewModel: ObservableObject {
    @Published var appDescription: String = ""
    @Published var state: GenerationState = .idle

    func generate() async {
        guard !appDescription.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        state = .loading
        do {
            let code = try await ClaudeService.generateAppIntents(for: appDescription)
            state = .success(code: code)
        } catch {
            state = .error(message: error.localizedDescription)
        }
    }
}
