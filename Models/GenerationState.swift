// GenerationState.swift
import SwiftUI
import Combine

enum GenerationState: Equatable {
    case idle
    case loading
    case success(code: String)
    case fixing(originalCode: String)
    case error(message: String)

    static func == (lhs: GenerationState, rhs: GenerationState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.loading, .loading): return true
        case (.success(let a), .success(let b)): return a == b
        case (.fixing(let a), .fixing(let b)): return a == b
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

    var originalCode: String? {
        if case .fixing(let code) = self { return code }
        return nil
    }

    var errorMessage: String? {
        if case .error(let msg) = self { return msg }
        return nil
    }
}

@MainActor
class IntentViewModel: ObservableObject {
    @Published var appDescription: String = ""
    @Published var issueDescription: String = ""
    @Published var state: GenerationState = .idle

    private var currentTask: Task<Void, Never>?

    var canGenerate: Bool {
        !appDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !state.isLoading
    }

    var canFix: Bool {
        !issueDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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

    func startFix(originalCode: String) {
        issueDescription = ""
        state = .fixing(originalCode: originalCode)
    }

    func fix() {
        guard canFix, let originalCode = state.originalCode else { return }
        currentTask?.cancel()
        currentTask = Task {
            let issue = issueDescription
            state = .loading
            do {
                let fixed = try await ClaudeService.fixAppIntents(originalCode: originalCode, issue: issue)
                guard !Task.isCancelled else { return }
                state = .success(code: fixed)
            } catch {
                guard !Task.isCancelled else { return }
                state = .error(message: error.localizedDescription)
            }
        }
    }

    func reset() {
        currentTask?.cancel()
        issueDescription = ""
        state = .idle
    }
}
