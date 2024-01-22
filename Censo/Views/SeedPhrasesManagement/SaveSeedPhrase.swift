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
    @State private var showPaywall = false

    var seedPhrase: SeedPhrase
    var session: Session
    @State var ownerState: API.OwnerState.Ready
    var isFirstTime: Bool
    var requestedLabel: String?
    var onSuccess: (API.OwnerState) -> Void

    var body: some View {
        if let newOwnerState {
            PhraseSaveSuccess(isFirstTime: isFirstTime) {
                onSuccess(newOwnerState)
            }
            .navigationTitle(Text("Add Seed Phrase"))
            .navigationBarTitleDisplayMode(.inline)
        } else {
            NavigationStack {
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
                        .accessibilityIdentifier("labelTextField")
                        
                        Text(label.isTooLong ? "Can't be longer than \(label.limit) characters" : " ")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.red)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical)
                    
                    Button {
                        if (ownerState.vault.seedPhrases.count == 1) {
                            showPaywall = true
                        } else {
                            save()
                        }
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
                    .accessibilityIdentifier("saveButton")
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
                .onAppear {
                    if (requestedLabel != nil && label.value == "") {
                        label.value = requestedLabel ?? ""
                    }
                }
            }
            .sheet(isPresented: $showPaywall, content: {
                PaywallGatedScreen(
                    session: session,
                    ownerState: Binding(
                        get: { .ready(ownerState) },
                        set: { newOwnerState in
                            switch newOwnerState {
                            case .ready(let ready):
                                ownerState = ready
                            case .initial:
                                break
                            }
                        }),
                    ignoreSubscriptionRequired: true,
                    onCancel: { dismiss() }) {
                    ProgressView().onAppear { 
                        save()
                    }
                }
            })
        }
    }

    private func save() {
        do {
            // first verify the master key signature if it is available
            if (ownerState.policy.masterKeySignature != nil) {
                let ownerApproverKey = try session.getOrCreateApproverKey(participantId: ownerState.policy.owner!.participantId, entropy: ownerState.policy.ownerEntropy?.data)
                let verified = try ownerApproverKey.verifySignature(for: ownerState.vault.publicMasterEncryptionKey.data, signature: ownerState.policy.masterKeySignature!)
                if (!verified) {
                    showError(CensoError.cannotVerifyMasterKeySignature)
                    return
                }
            }
            let phraseData = try seedPhrase.toData()
            let encryptedSeedPhrase = try EncryptionKey
                .generateFromPublicExternalRepresentation(base58PublicKey: ownerState.vault.publicMasterEncryptionKey)
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
            SaveSeedPhrase(seedPhrase: .bip39(words: [""]), session: .sample, ownerState: .sample, isFirstTime: true, onSuccess: { _ in })
        }
        .foregroundColor(Color.Censo.primaryForeground)
    }
}
#endif
