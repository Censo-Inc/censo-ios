//
//  PastePhrase.swift
//  Censo
//
//  Created by Ben Holzman on 10/16/23.
//

import SwiftUI
import CryptoKit
import Moya

enum PhraseValidityError: Error, LocalizedError {
    case invalid(BIP39InvalidReason)

    var errorDescription: String? {
        switch self {
        case .invalid(let reason):
            return reason.description
        }
    }
}

struct PastePhrase: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss

    @State private var showingError = false
    @State private var error: Error?
    @State private var pastedPhrase: String = ""
    @State private var showingVerification = false

    var onComplete: (API.OwnerState) -> Void
    var session: Session
    var ownerState: API.OwnerState.Ready

    var body: some View {
        NavigationStack {
            VStack {
                Button {
                    validatePhrase()
                } label: {
                    Text("Paste Phrase")
                }
                .buttonStyle(RoundedButtonStyle())
            }
            .padding()
            .frame(maxWidth: .infinity)
            .navigationTitle(Text("Paste Seed Phrase"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.black)
                    }
                }
            }
            .alert("Error", isPresented: $showingError, presenting: error) { _ in
                Button { } label: { Text("OK") }
            } message: { error in
                Text(error.localizedDescription)
            }
            .navigationDestination(isPresented: $showingVerification, destination: {
                SeedVerification(
                    words: pastedPhrase.split(separator: " ").map(String.init),
                    session: session,
                    publicMasterEncryptionKey: ownerState.vault.publicMasterEncryptionKey
                ) { ownerState in
                    onComplete(ownerState)
                    dismiss()
                }
            })
        }
    }

    private func validatePhrase() {
        guard let phrase = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
            return
        }

        if let result = BIP39.validateSeedPhrase(phrase: phrase) {
            showingError = true
            error = PhraseValidityError.invalid(result)
        } else {
            pastedPhrase = phrase
            showingVerification = true
        }
    }
}

#if DEBUG
#Preview {
    PastePhrase(onComplete: {_ in}, session: .sample, ownerState: API.OwnerState.Ready(policy: .sample, vault: .sample))
}
#endif
