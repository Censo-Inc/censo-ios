//
//  PastePhrase.swift
//  Vault
//
//  Created by Ben Holzman on 10/16/23.
//

import SwiftUI
import CryptoKit
import Moya

enum PhraseValidity {
    case notChecked
    case valid
    case invalid(BIP39InvalidReason)
}

extension PhraseValidity {
    func isValid() -> Bool {
        switch (self) {
        case .valid:
            return true
        default:
            return false
        }
    }
}

struct PastePhrase: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss

    var onComplete: (API.OwnerState) -> Void

    var session: Session
    @State var phrase: String = "media squirrel pass doll leg across modify candy dash glass amused scorpion"
    @State var nickname: String = ""

    var ownerState: API.OwnerState.Ready
    @State private var inProgress = false
    @State private var showingError = false
    @State private var error: Error?
    @FocusState private var isPhraseFocused: Bool
    @FocusState private var isNicknameFocused: Bool

    @State private var phraseValidation: PhraseValidity = .notChecked

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Paste your phrase")
                        .font(.system(size: 24, weight: .semibold))
                        .padding(.vertical)
                    switch (phraseValidation) {
                    case .notChecked, .invalid:
                        TextField("cable solution media ...", text: $phrase, axis: .vertical)
                            .lineLimit(6, reservesSpace: true)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isPhraseFocused)
                            .onChange(of: isPhraseFocused) { isFocused in
                                if (isFocused) {
                                    phraseValidation = .notChecked
                                }
                            }
                            .onChange(of: phrase) { newPhrase in
                                validatePhrase()
                            }
                            .textInputAutocapitalization(.never)
                            .padding()
                        switch (phraseValidation) {
                        case .notChecked:
                            EmptyView()
                        case .valid:
                            EmptyView()
                        case .invalid(let reason):
                            VStack(alignment: .center) {
                                Text(reason.description)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(Color.red)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)

                        }
                    case .valid:
                        VStack(alignment: .center) {
                            let phraseValidMessage = "✓ Phrase \"\(phrasePrefix())...\" is valid"
                            Text(phraseValidMessage)
                                .foregroundStyle(Color.green)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        Spacer()

                        Text("Add a nickname")
                            .font(.system(size: 24, weight: .semibold))
                            .padding(.vertical)


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
                        .focused($isNicknameFocused)
                        .textFieldStyle(.roundedBorder)
                        .padding()
                        .onAppear {
                            isNicknameFocused = true
                        }

                        Button {
                            storeSecret()
                        } label: {
                            Text("Save")
                                .frame(maxWidth: .infinity)
                        }
                        .disabled(
                            inProgress ||
                            !phraseValidation.isValid() ||
                            nickname.trimmingCharacters(in: .whitespaces).isEmpty
                        )
                        .buttonStyle(RoundedButtonStyle())
                        .padding()
                    }
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
                    Text("Failed to store phrase.\n\(error.localizedDescription)")
                }
            }
        }
    }

    private func validatePhrase() {
        let result = BIP39.validateSeedPhrase(phrase: phrase)
        switch (result) {
        case .none:
            phraseValidation = .valid
            isPhraseFocused = false
        case .some(let error):
            phraseValidation = .invalid(error)
        }
    }

    private func phrasePrefix() -> String {
        return String(
            phrase
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
                .prefix(through: phrase.index(phrase.startIndex, offsetBy: 20)))
    }

    private func storeSecret() {
        do {
            inProgress = true
            let secretData = try BIP39.phraseToBinaryEntropy(phrase: phrase)

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

#if DEBUG
#Preview {
    PastePhrase(onComplete: {_ in}, session: .sample, ownerState: API.OwnerState.Ready(policy: .sample, vault: .sample))
}
#endif
