// ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = IntentViewModel()

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .error:
                InputView(viewModel: viewModel)
            case .loading:
                LoadingView()
            case .success:
                OutputView(viewModel: viewModel, onBack: { viewModel.reset() })
            case .fixing:
                FixView(viewModel: viewModel)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.state)
    }
}
