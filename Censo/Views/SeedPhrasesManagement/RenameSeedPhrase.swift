//
//  RenameSeedPhrase.swift
//  Censo
//
//  Created by Brendan Flood on 1/22/24.
//

import SwiftUI

struct RenameSeedPhrase: View {
    @EnvironmentObject var ownerRepository: OwnerRepository
    @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController
    
    @StateObject private var label = PhraseLabel()
    @State private var inProgress = false
    @State private var showingError = false
    @State private var error: Error?

    var seedPhrase: API.SeedPhrase
    var onComplete: () -> Void

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Spacer()
                
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
            .navigationInlineTitle("Rename seed phrase")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    DismissButton(icon: .close)
                }
            }
            .alert("Error", isPresented: $showingError, presenting: error) { _ in
                Button { } label: { Text("OK") }
            } message: { error in
                Text(error.localizedDescription)
            }
            .onAppear {
                label.value = seedPhrase.label
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
        ownerRepository.updateSeedPhraseMetaInfo(
            guid: seedPhrase.guid,
            .setLabel(value: label.value)
        ) { result in
            inProgress = false

            switch result {
            case .success(let payload):
                ownerStateStoreController.replace(payload.ownerState)
                onComplete()
            case .failure(let error):
                showError(error)
            }
        }
    }
}

#if DEBUG
#Preview {
    LoggedInOwnerPreviewContainer {
        RenameSeedPhrase(
            seedPhrase: API.OwnerState.Ready.sample.vault.seedPhrases[0],
            onComplete: {}
        )
    }
}
#endif
