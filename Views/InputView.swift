// InputView.swift
import SwiftUI

struct InputView: View {
    @ObservedObject var viewModel: IntentViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Intent")
                .font(.largeTitle)
                .bold()
                .padding(.top, 32)
                .padding(.horizontal, 24)

            Text("Make your app visible to Siri AI")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 4)
                .padding(.horizontal, 24)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )

                if viewModel.appDescription.isEmpty {
                    Text("Describe your iOS app...\n\nExample: A recipe app where users save recipes and set cooking timers")
                        .font(.body)
                        .foregroundColor(Color(.tertiaryLabel))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $viewModel.appDescription)
                    .font(.body)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
            }
            .frame(minHeight: 220)
            .padding(.horizontal, 24)
            .padding(.top, 20)

            if let errorMessage = viewModel.state.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
            }

            Spacer()

            Button {
                viewModel.generate()
            } label: {
                Text("Generate App Intents")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        viewModel.canGenerate
                            ? Color.accentColor
                            : Color.accentColor.opacity(0.4)
                    )
                    .cornerRadius(14)
            }
            .disabled(!viewModel.canGenerate)
            .animation(.easeInOut(duration: 0.2), value: viewModel.canGenerate)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
