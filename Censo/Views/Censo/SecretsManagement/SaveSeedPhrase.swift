//
//  SaveSeedPhrase.swift
//  Censo
//
//  Created by Ata Namvari on 2023-10-19.
//

import SwiftUI
import Moya
import CryptoKit

struct SaveSeedPhrase: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.apiProvider) var apiProvider

    @State private var label = ""
    @State private var showingDismissAlert = false
    @State private var inProgress = false
    @State private var newOwnerState: API.OwnerState?
    @State private var showingError = false
    @State private var error: Error?

    var words: [String]
    var session: Session
    var publicMasterEncryptionKey: Base58EncodedPublicKey
    var onSuccess: (API.OwnerState) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()

            Text("Add a label")
                .font(.title2.bold())

            Text(
                """
                Now, give your seed phrase a label of your choice so you can identify it in the future.

                This will be secured by your face scan and not shared with anyone.
                """
            )

            TextField(text: $label) {
                Text("Enter a label...")
            }
            .textFieldStyle(RoundedTextFieldStyle())
            .padding(.vertical)

            Button {
                save()
            } label: {
                Group {
                    if inProgress {
                        ProgressView()
                    } else {
                        Text("Save")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .disabled(label.isEmpty || inProgress)
        }
        .padding(50)
        .buttonStyle(RoundedButtonStyle())
        .navigationTitle(Text("Add Seed Phrase"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                BackButton()
            }
        })
        .alert("Are you sure?", isPresented: $showingDismissAlert) {
            Button(role: .destructive, action: { dismiss() }) {
                Text("Exit")
            }
        } message: {
            Text("Your progress will be lost")
        }
        .alert("Error", isPresented: $showingError, presenting: error) { _ in
            Button { } label: { Text("OK") }
        } message: { error in
            Text("Failed to save phrase.\n\(error.localizedDescription)")
        }
        .interactiveDismissDisabled()
        .navigationDestination(isPresented: .constant(newOwnerState != nil)) {
            PhraseSaveSuccess(label: label) {
                onSuccess(newOwnerState!)
            }
        }
    }

    private func save() {
        do {
            let secretData = words.joined(separator: " ").data(using: .utf8)!
            let encryptedSeedPhrase = try EncryptionKey
                .generateFromPublicExternalRepresentation(base58PublicKey: publicMasterEncryptionKey)
                .encrypt(data: secretData)

            let payload = API.StoreSecretApiRequest(
                encryptedSeedPhrase: encryptedSeedPhrase,
                seedPhraseHash: SHA256.hash(data: secretData).compactMap { String(format: "%02x", $0) }.joined(),
                label: label
            )

            inProgress = true

            apiProvider.decodableRequest(with: session, endpoint: .storeSecret(payload)) { (result: Result<API.StoreSecretApiResponse, MoyaError>) in
                inProgress = false

                switch result {
                case .success(let payload):
                    newOwnerState = payload.ownerState
                case .failure(let error):
                    showError(error)
                }
            }
        } catch {
            showError(error)
            return
        }
    }

    private func showError(_ error: Error) {
        inProgress = false
        self.error = error
        self.showingError = true
    }
}


#if DEBUG
struct SaveSeedPhrase_Preview: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SaveSeedPhrase(words: [""], session: .sample, publicMasterEncryptionKey: .sample, onSuccess: { _ in })
        }
    }
}
#endif
