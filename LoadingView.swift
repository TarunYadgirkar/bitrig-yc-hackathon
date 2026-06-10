// LoadingView.swift
import SwiftUI

struct LoadingView: View {
    @State private var opacity: Double = 1.0

    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.3)
                .tint(.accentColor)

            Text("Generating your App Intents...")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .opacity(opacity)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 1.2).repeatForever(autoreverses: true)
                    ) {
                        opacity = 0.3
                    }
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
