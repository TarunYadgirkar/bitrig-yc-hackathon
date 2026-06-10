// FixView.swift
import SwiftUI

struct FixView: View {
    @ObservedObject var viewModel: IntentViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            Text("What's Siri getting wrong?")
                .font(.largeTitle)
                .bold()
                .padding(.top, 32)
                .padding(.horizontal, 24)

            Text("Describe the issue and we'll fix the implementation")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 4)
                .padding(.horizontal, 24)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(uiColor: .secondarySystemBackground))
                    )

                if viewModel.issueDescription.isEmpty {
                    Text("Example: When a user says 'Send a message to Alex on Discord', Siri says it can't find a recipient — there's no contact parameter in the intent...")
                        .font(.body)
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $viewModel.issueDescription)
                    .font(.body)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .focused($isFocused)
            }
            .frame(minHeight: 220)
            .padding(.horizontal, 24)
            .padding(.top, 20)

            Spacer()

            Button {
                viewModel.fix()
            } label: {
                Text("Fix It")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(viewModel.canFix ? Color.orange : Color.orange.opacity(0.4))
                    .cornerRadius(14)
            }
            .disabled(!viewModel.canFix)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { isFocused = false }
            }
        }
    }
}
