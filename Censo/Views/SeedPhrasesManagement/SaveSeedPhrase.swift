//
//  SaveSeedPhrase.swift
//  Censo
//
//  Created by Ata Namvari on 2023-10-19.
//

import SwiftUI
import CryptoKit
import Sentry

struct SaveSeedPhrase: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var ownerRepository: OwnerRepository
    @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController
    
    @StateObject private var label = PhraseLabel()
    @State private var encryptedNotes: API.SeedPhraseEncryptedNotes?
    @State private var inProgress = false
    @State private var newOwnerState: API.OwnerState?
    @State private var showingError = false
    @State private var error: Error?
    @State private var showPaywall = false
    
    enum EditStep {
        case addNotes
        case setLabel
    }
    @State private var editStep: EditStep = .addNotes

    var seedPhrase: SeedPhrase
    var ownerState: API.OwnerState.Ready
    var isFirstTime: Bool
    var requestedLabel: String?
    var onSuccess: () -> Void
    private var canAddNotes: Bool
    
    init(seedPhrase: SeedPhrase, ownerState: API.OwnerState.Ready, isFirstTime: Bool, requestedLabel: String? = nil, onSuccess: @escaping () -> Void) {
        self.canAddNotes = ownerState.policy.beneficiary?.isActivated == true
        self._editStep = State(initialValue: canAddNotes ? .addNotes : .setLabel)
        self.seedPhrase = seedPhrase
        self.ownerState = ownerState
        self.isFirstTime = isFirstTime
        self.requestedLabel = requestedLabel
        self.onSuccess = onSuccess
    }

    var body: some View {
        if let newOwnerState {
            PhraseSaveSuccess(isFirstTime: isFirstTime) {
                ownerStateStoreController.replace(newOwnerState)
                onSuccess()
            }
            .navigationInlineTitle("Seed phrase saved")
        } else {
            NavigationStack {
                Group {
                    switch (editStep) {
                    case .addNotes:
                        SeedPhraseNotes.Editor(
                            policy: ownerState.policy,
                            publicMasterEncryptionKey: ownerState.vault.publicMasterEncryptionKey,
                            initialValue: self.encryptedNotes,
                            saveButtonLabel: "Continue",
                            forBeneficiary: false,
                            dismissButtonIcon: .back,
                            onSave: { newValue in
                                self.encryptedNotes = newValue
                                self.editStep = .setLabel
                            }
                        )
                        .navigationInlineTitle("Add notes")
                    case .setLabel:
                        VStack(alignment: .leading, spacing: 0) {
                            Spacer()
                            
                            Text("Label your seed phrase")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text("Give your seed phrase a unique label so you can easily identify it.")
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.vertical)
                            
                            VStack(spacing: 0) {
                                TextField(text: $label.value) {
                                    Text("Enter a label...")
                                }
                                .textFieldStyle(RoundedTextFieldStyle())
                                .accessibilityIdentifier("labelTextField")
                                .padding(.top)
                                
                                Text(label.isTooLong ? "Can't be longer than \(label.limit) characters" : " ")
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(Color.red)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.bottom)
                            }
                            
                            Button {
                                if (ownerState.vault.seedPhrases.count == 1 && !Configuration.paywallDisabled) {
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
                                            .font(.headline)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(RoundedButtonStyle())
                            .disabled(!label.isValid || inProgress)
                            .accessibilityIdentifier("saveButton")
                        }
                        .padding(.vertical)
                        .padding(.horizontal, 32)
                        .navigationInlineTitle("Save seed phrase")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                if canAddNotes {
                                    DismissButton(icon: .back, action: {
                                        self.editStep = .addNotes
                                    })
                                } else {
                                    DismissButton(icon: .back)
                                }
                            }
                        }
                    }
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
                NavigationStack {
                    PaywallGatedScreen(
                        ownerState: .ready(ownerState),
                        ignoreSubscriptionRequired: true,
                        onCancel: { dismiss() }) {
                            ProgressView().onAppear {
                                save()
                            }
                        }
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                DismissButton(icon: .close, action: {
                                    showPaywall = false
                                })
                            }
                        }
                }
            })
        }
    }

    private func save() {
        do {
            guard let ownerEntropy = ownerState.policy.ownerEntropy else {
                throw CensoError.invalidEntropy
            }
            // first verify the master key signature if it is available
            if (ownerState.policy.masterKeySignature != nil) {
                let ownerApproverKey = try ownerRepository.getOrCreateApproverKey(keyId: ownerState.policy.owner!.participantId, entropy: ownerEntropy.data)
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

            inProgress = true

            ownerRepository.storeSeedPhrase(API.StoreSeedPhraseApiRequest(
                encryptedSeedPhrase: encryptedSeedPhrase,
                seedPhraseHash: SHA256.hash(data: phraseData).compactMap { String(format: "%02x", $0) }.joined(),
                label: label.value,
                encryptedNotes: encryptedNotes
            )) { result in
                inProgress = false

                switch result {
                case .success(let payload):
                    newOwnerState = payload.ownerState
                case .failure(let error):
                    showError(error)
                }
            }
        } catch {
            SentrySDK.captureWithTag(error: error, tagValue: "Save seed phrase")
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
        LoggedInOwnerPreviewContainer {
            NavigationStack {
                SaveSeedPhrase(
                    seedPhrase: .bip39(words: [""]),
                    ownerState: .sample,
                    isFirstTime: true,
                    onSuccess: {}
                )
            }
        }
    }
}
#endif
