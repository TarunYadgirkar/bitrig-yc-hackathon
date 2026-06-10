// ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = IntentViewModel()

    var body: some View {
        switch viewModel.state {
        case .idle, .error:
            InputView(viewModel: viewModel)
        case .loading:
            LoadingView()
        case .success:
            OutputView(viewModel: viewModel)
        }
    }
}
