//
//  PastePhrase.swift
//  Vault
//
//  Created by Ben Holzman on 10/16/23.
//

import SwiftUI
import CryptoKit
import Moya

struct PastePhrase: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss

    var onComplete: (API.OwnerState) -> Void

    var session: Session
    @State var phrase: String = ""
    @State var nickname: String = ""
    var ownerState: API.OwnerState.Ready
    @State private var inProgress = false
    @State private var showingError = false
    @State private var error: Error?
    @FocusState private var isPhraseFocused: Bool
    @State private var phraseValidationError: BIP39Error?
    let bip39Validator = BIP39Validator()

    var body: some View {
        
        VStack(alignment: .leading) {
            Text("Paste your phrase")
                .font(.system(size: 24, weight: .semibold))
            VStack {
                TextField(text: $phrase) {
                    Text("cable solution media ...")
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isPhraseFocused)
                .onChange(of: isPhraseFocused) { isFocused in
                    if (isFocused) {
                        phraseValidationError = nil
                    } else {
                        do {
                            try bip39Validator.validateSeedPhrase(phrase: phrase)
                        } catch let error as BIP39Error {
                            phraseValidationError = error
                        } catch {}
                    }
                }
                .textInputAutocapitalization(.never)

                if (phraseValidationError != nil) {
                    Text(phraseValidationError!.description).foregroundStyle(Color.red)
                        .font(.system(size: 14, weight: .semibold))
                } else {
                    Spacer()
                }
            }
            .frame(height: 57)
            .padding()
            
            Text("Add a nickname")
                .font(.system(size: 24, weight: .semibold))
            
            Text("Give your seed phrase a nickname of your choice so you can identify it in the future.")
                .font(.system(size: 14))
                .padding(EdgeInsets(top: 3, leading: 10, bottom: 3, trailing: 10))
                .fixedSize(horizontal: false, vertical: true)
            Text("This will be secured by your face scan and not shared with anyone.")
                .font(.system(size: 14))
                .padding(EdgeInsets(top: 3, leading: 10, bottom: 3, trailing: 10))
                .fixedSize(horizontal: false, vertical: true)
            TextField(text: $nickname) {
                Text("Enter a nickname...")
            }
            .textFieldStyle(.roundedBorder)
            .padding()
            
            Button {
                storeSecret()
            } label: {
                Text("Save")
                    .padding()
            }
            .disabled(
                inProgress ||
                phraseValidationError != nil ||
                phrase.trimmingCharacters(in: .whitespaces).isEmpty ||
                nickname.trimmingCharacters(in: .whitespaces).isEmpty
            )
            .buttonStyle(RoundedButtonStyle())
            .padding()
        }
        .padding()
        .navigationTitle(Text("Paste Seed Phrase"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                BackButton()
            }
        }
        .alert("Error", isPresented: $showingError, presenting: error) { _ in
            Button { } label: { Text("OK") }
        } message: { error in
            Text("Failed to store phrase.\n\(error.localizedDescription)")
        }
    
    }
    
    private func storeSecret() {
        do {
            inProgress = true
            let secretData = phrase.trimmingCharacters(in: .whitespaces).data(using: .utf8)!
            let encryptedSeedPhrase = try EncryptionKey
                .generateFromPublicExternalRepresentation(base58PublicKey: ownerState.vault.publicMasterEncryptionKey)
                .encrypt(data: secretData)

            let payload = API.StoreSecretApiRequest(
                encryptedSeedPhrase: encryptedSeedPhrase,
                seedPhraseHash: SHA256.hash(data: secretData).compactMap { String(format: "%02x", $0) }.joined(),
                label: nickname.trimmingCharacters(in: .whitespaces)
            )
            apiProvider.decodableRequest(with: session, endpoint: .storeSecret(payload)) { (result: Result<API.StoreSecretApiResponse, MoyaError>) in
                switch result {
                case .success(let payload):
                    onComplete(payload.ownerState)
                    dismiss()
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

#Preview {
    PastePhrase(onComplete: {_ in}, session: .sample, ownerState: API.OwnerState.Ready(policy: .sample, vault: .sample))
}
