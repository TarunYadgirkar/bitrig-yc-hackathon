// GenerationState.swift
import SwiftUI
import Combine

// MARK: - State Enum

enum GenerationState: Equatable {
    case idle
    case loading
    case success(code: String)
    case error(message: String)

    static func == (lhs: GenerationState, rhs: GenerationState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.loading, .loading): return true
        case (.success(let a), .success(let b)): return a == b
        case (.error(let a), .error(let b)): return a == b
        default: return false
        }
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var code: String? {
        if case .success(let code) = self { return code }
        return nil
    }

    var errorMessage: String? {
        if case .error(let msg) = self { return msg }
        return nil
    }
}

// MARK: - ViewModel

@MainActor
class IntentViewModel: ObservableObject {
    @Published var appDescription: String = ""
    @Published var state: GenerationState = .idle

    // Prevents double-taps from firing two API calls
    private var currentTask: Task<Void, Never>?

    var canGenerate: Bool {
        !appDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !state.isLoading
    }

    func generate() {
        guard canGenerate else { return }

        currentTask?.cancel()
        currentTask = Task {
            state = .loading
            do {
                let code = try await ClaudeService.generateAppIntents(for: appDescription)
                guard !Task.isCancelled else { return }
                state = .success(code: code)
            } catch {
                guard !Task.isCancelled else { return }
                state = .error(message: error.localizedDescription)
            }
        }
    }

    func reset() {
        currentTask?.cancel()
        // Preserve the description so the user can tweak and retry
        state = .idle
    }
}
