//
//  SeedPhraseNotes.swift
//  Censo
//
//  Created by Anton Onyshchenko on 09.02.24.
//

import Foundation
import SwiftUI
import Sentry

struct SeedPhraseNotes: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var ownerRepository: OwnerRepository
    @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController
    
    var policy: API.Policy
    var publicMasterEncryptionKey: Base58EncodedPublicKey
    var seedPhrase: API.SeedPhrase
    var forBeneficiary: Bool
    var dismissButtonIcon: DismissButton.Icon
    
    @State private var error: Error?
    @State private var showErrorAlert: Bool = false
    @State private var submitInProgress: Bool = false
    
    var body: some View {
        Editor(
            policy: policy,
            publicMasterEncryptionKey: publicMasterEncryptionKey,
            initialValue: seedPhrase.encryptedNotes,
            disabled: submitInProgress,
            saveButtonLabel: "Save",
            forBeneficiary: forBeneficiary,
            dismissButtonIcon: dismissButtonIcon,
            onSave: { newValue in
                submit(newValue)
            }
        )
        .errorAlert(isPresented: $showErrorAlert, presenting: error)
    }
    
    private func submit(_ encryptedNotes: API.SeedPhraseEncryptedNotes?) {
        self.submitInProgress = true
        
        let update: API.UpdateSeedPhraseMetaInfoApiRequest.Update
        if let encryptedNotes = encryptedNotes {
            update = API.UpdateSeedPhraseMetaInfoApiRequest.Update.setNotes(value: encryptedNotes)
        } else {
            update = API.UpdateSeedPhraseMetaInfoApiRequest.Update.deleteNotes
        }
        
        ownerRepository.updateSeedPhraseMetaInfo(guid: seedPhrase.guid, update, { result in
            self.submitInProgress = false
            
            switch result {
            case .success(let payload):
                ownerStateStoreController.replace(payload.ownerState)
                dismiss()
            case .failure(let error):
                self.error = error
                self.showErrorAlert = true
            }
        })
    }
    
    struct Editor: View {
        @Environment(\.dismiss) var dismiss
        @EnvironmentObject var ownerRepository: OwnerRepository
        
        var policy: API.Policy
        var publicMasterEncryptionKey: Base58EncodedPublicKey
        var initialValue: API.SeedPhraseEncryptedNotes?
        var disabled: Bool = false
        var saveButtonLabel: String
        var forBeneficiary: Bool
        var dismissButtonIcon: DismissButton.Icon
        var onSave: (API.SeedPhraseEncryptedNotes?) -> Void
        
        enum Step {
            case initial
            case decryptionFailed(Error)
            case editing
        }
        
        @State private var step: Step = .initial
        @State private var initialText: String = ""
        @State private var text: String = ""
        @State private var error: Error?
        @State private var showErrorAlert: Bool = false
        @State private var showingDismissAlert = false
        
        var body: some View {
            Group {
                switch (step) {
                case .initial:
                    ProgressView()
                        .onAppear(perform: decrypt)
                case .decryptionFailed(let error):
                    RetryView(error: error, action: decrypt)
                        .padding(.horizontal, 32)
                        .padding(.vertical)
                case .editing:
                    ScrollView {
                        TextField(
                            "Provide any information which \(forBeneficiary ? "your beneficiary" : "you") might need to access your crypto.\n  For example, you might want to provide the chains and wallets this phrase is used in, or specific tokens or dApps of interest.",
                            text: $text,
                            axis: .vertical
                        )
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .disabled(disabled)
                        .lineLimit(10, reservesSpace: true)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1))
                                .foregroundColor(.Censo.gray224)
                        )
                        .padding(.vertical)
                        .padding(.horizontal, 32)
                        
                        Button {
                            save()
                        } label: {
                            Text(saveButtonLabel)
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(RoundedButtonStyle())
                        .padding(.horizontal, 32)
                        .padding(.bottom)
                        .disabled(disabled)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .errorAlert(isPresented: $showErrorAlert, presenting: error)
                }
            }
            .alert("Are you sure?", isPresented: $showingDismissAlert) {
                Button(role: .destructive, action: { dismiss() }) {
                    Text("Exit")
                }
            } message: {
                Text("Unsaved notes will be lost")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    DismissButton(icon: dismissButtonIcon, action: {
                        if text != initialText {
                            self.showingDismissAlert = true
                        } else {
                            dismiss()
                        }
                    })
                }
            }
        }
        
        private func decrypt() {
            do {
                self.text = try initialValue.map({
                    try ownerRepository.decryptStringWithApproverKey(data: $0.ownerApproverKeyEncryptedText, policy: policy)
                }) ?? ""
                self.initialText = self.text
                self.step = .editing
            } catch {
                SentrySDK.captureWithTag(error: error, tagValue: "Seed phrase notes editing")
                self.error = CensoError.failedToDecryptSeedPhraseNotes
            }
        }
        
        private func save() {
            do {
                if text.isEmpty {
                    onSave(nil)
                } else {
                    let data = text.data(using: .utf8)!
                    let encryptedNotes = API.SeedPhraseEncryptedNotes(
                        ownerApproverKeyEncryptedText: try ownerRepository.encryptWithApproverPublicKey(data: data, policy: policy),
                        masterKeyEncryptedText: try publicMasterEncryptionKey.toEncryptionKey().encrypt(data: data)
                    )
                    onSave(encryptedNotes)
                }
            } catch {
                SentrySDK.captureWithTag(error: error, tagValue: "Seed phrase notes editing")
                self.error = CensoError.failedToEncryptSeedPhraseNotes
                self.showErrorAlert = true
            }
        }
    }
}
