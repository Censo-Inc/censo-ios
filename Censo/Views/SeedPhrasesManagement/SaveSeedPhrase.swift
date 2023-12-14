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
    
    @StateObject private var label = PhraseLabel()
    @State private var showingDismissAlert = false
    @State private var inProgress = false
    @State private var newOwnerState: API.OwnerState?
    @State private var showingError = false
    @State private var error: Error?

    var words: [String]
    var session: Session
    var publicMasterEncryptionKey: Base58EncodedPublicKey
    var isFirstTime: Bool
    var onSuccess: (API.OwnerState) -> Void

    var body: some View {
        if let newOwnerState {
            PhraseSaveSuccess(isFirstTime: isFirstTime) {
                onSuccess(newOwnerState)
            }
            .navigationTitle(Text("Add Seed Phrase"))
            .navigationBarTitleDisplayMode(.inline)
        } else {
            VStack(alignment: .leading, spacing: 20) {
                Spacer()

                Text("Label your seed phrase")
                    .font(.title2.bold())

                Text("Give your seed phrase a unique label so you can easily identify it.")
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 0) {
                    TextField(text: $label.value) {
                        Text("Enter a label...")
                    }
                    .textFieldStyle(RoundedTextFieldStyle())
                    
                    Text(label.isTooLong ? "Can't be longer than \(label.limit) characters" : " ")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.red)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .padding(.vertical)

                Button {
                    save()
                } label: {
                    Group {
                        if inProgress {
                            ProgressView()
                        } else {
                            Text("Save seed phrase")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(!label.isValid || inProgress)
            }
            .padding(30)
            .buttonStyle(RoundedButtonStyle())
            .navigationTitle(Text("Add Seed Phrase"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
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
        }
    }

    private func save() {
        do {
            let phraseData = try BIP39.phraseToBinaryData(words: words)
            let encryptedSeedPhrase = try EncryptionKey
                .generateFromPublicExternalRepresentation(base58PublicKey: publicMasterEncryptionKey)
                .encrypt(data: phraseData)

            let payload = API.StoreSeedPhraseApiRequest(
                encryptedSeedPhrase: encryptedSeedPhrase,
                seedPhraseHash: SHA256.hash(data: phraseData).compactMap { String(format: "%02x", $0) }.joined(),
                label: label.value
            )

            inProgress = true

            apiProvider.decodableRequest(with: session, endpoint: .storeSeedPhrase(payload)) { (result: Result<API.StoreSeedPhraseApiResponse, MoyaError>) in
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
            SaveSeedPhrase(words: [""], session: .sample, publicMasterEncryptionKey: .sample, isFirstTime: true, onSuccess: { _ in })
        }
        .foregroundColor(Color.Censo.primaryForeground)
    }
}
#endif
