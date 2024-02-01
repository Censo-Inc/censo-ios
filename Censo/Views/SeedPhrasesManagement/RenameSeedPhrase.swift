//
//  RenameSeedPhrase.swift
//  Censo
//
//  Created by Brendan Flood on 1/22/24.
//

import SwiftUI
import Moya

struct RenameSeedPhrase: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.apiProvider) var apiProvider
    
    @StateObject private var label = PhraseLabel()
    @State private var inProgress = false
    @State private var showingError = false
    @State private var error: Error?

    var session: Session
    var ownerState: API.OwnerState.Ready
    var editingIndex: Int
    var onComplete: (API.OwnerState) -> Void

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Spacer()
                
                Text("Rename seed phrase")
                    .font(.title2.bold())
                
                Text("Give your seed phrase a different label")
                    .fixedSize(horizontal: false, vertical: true)
                
                VStack(spacing: 0) {
                    TextField(text: $label.value) {
                        Text("Enter a label...")
                    }
                    .textFieldStyle(RoundedTextFieldStyle())
                    .accessibilityIdentifier("renameTextField")
                    
                    Text(label.isTooLong ? "Can't be longer than \(label.limit) characters" : " ")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.red)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .padding(.vertical)
                
                Button {
                    updateSeedPhraseLabel()
                } label: {
                    Group {
                        if inProgress {
                            ProgressView()
                        } else {
                            Text("Rename")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(!label.isValid || inProgress)
                .accessibilityIdentifier("saveButton")
            }
            .padding(30)
            .buttonStyle(RoundedButtonStyle())
            .navigationTitle(Text("Rename Seed Phrase"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                       dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            })
            .alert("Error", isPresented: $showingError, presenting: error) { _ in
                Button { } label: { Text("OK") }
            } message: { error in
                Text(error.localizedDescription)
            }
            .onAppear {
                label.value = ownerState.vault.seedPhrases[editingIndex].label
            }
        }
    }

    private func showError(_ error: Error) {
        inProgress = false
        self.error = error
        self.showingError = true
    }
    
    private func updateSeedPhraseLabel() {
        inProgress = true
        apiProvider.decodableRequest(
            with: session,
            endpoint: .updateSeedPhrase(
                guid: ownerState.vault.seedPhrases[editingIndex].guid,
                label: label.value
            )
        ) { (result: Result<API.UpdateSeedPhraseApiResponse, MoyaError>) in
            inProgress = false

            switch result {
            case .success(let payload):
                onComplete(payload.ownerState)
            case .failure(let error):
                showError(error)
            }
        }
    }
}

#if DEBUG
#Preview {
    RenameSeedPhrase(session: .sample, ownerState: .sample, editingIndex: 0, onComplete: {_ in })
}
#endif
