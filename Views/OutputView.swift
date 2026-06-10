// OutputView.swift
import SwiftUI

struct OutputView: View {
    @ObservedObject var viewModel: IntentViewModel
    var onBack: () -> Void

    @State private var didCopy = false

    private var code: String { viewModel.state.code ?? "" }

    var body: some View {
        VStack(spacing: 0) {

            // Header
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                }

                Spacer()

                Text("App Intents")
                    .font(.headline)

                Spacer()

                ShareLink(item: code) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Divider()

            // Ready badge
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                Text("Ready to copy")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Code block
            ScrollView {
                Text(code)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(Color(red: 0.851, green: 0.851, blue: 0.851))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            }
            .background(Color(red: 0.118, green: 0.118, blue: 0.118))
            .frame(maxHeight: .infinity)

            VStack(spacing: 10) {
                // Copy button
                Button {
                    UIPasteboard.general.string = code
                    withAnimation(.easeInOut(duration: 0.2)) { didCopy = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation(.easeInOut(duration: 0.2)) { didCopy = false }
                    }
                } label: {
                    Label(
                        didCopy ? "Copied!" : "Copy Code",
                        systemImage: didCopy ? "checkmark" : "doc.on.doc"
                    )
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(didCopy ? Color.green : Color.accentColor)
                    .cornerRadius(14)
                }

                // Fix button — new
                Button {
                    viewModel.startFix(originalCode: code)
                } label: {
                    Label("Siri's not getting it right?", systemImage: "wrench.and.screwdriver")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }
}
