//
//  PhrasesAccessAvailable.swift
//  Censo
//
//  Created by Anton Onyshchenko on 30.11.23.
//

import Foundation
import SwiftUI
import Moya
import raygun4apple

struct PhrasesAccessAvailable: View {
    @Environment(\.apiProvider) var apiProvider
    
    var session: Session
    var ownerState: API.OwnerState.Ready
    var onFinished: () -> Void
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    
    enum Step {
        case showingList
        case intro(phraseIndex: Int)
        case retrievingShards(phraseIndex: Int)
        case showingSeedPhrase(phraseIndex: Int, phrase: [String], start: Date)
    }
    
    @State private var step: Step = .showingList
    @State private var viewedPhrases: [Int] = []
    @State private var showingError = false
    @State private var error: Error?
    
    var body: some View {
        switch (step) {
        case .showingList:
            ShowPhraseList(
                session: session,
                ownerState: ownerState,
                onOwnerStateUpdated: onOwnerStateUpdated,
                viewedPhrases: viewedPhrases,
                onPhraseSelected: { selectedPhraseIndex in
                    self.step = .intro(phraseIndex: selectedPhraseIndex)
                },
                onFinished: onFinished
            )
            .navigationTitle(Text("Access"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .interactiveDismissDisabled()
            .alert("Error", isPresented: $showingError, presenting: error) { _ in
                Button {
                } label: {
                    Text("OK")
                }
            } message: { error in
                Text(error.localizedDescription)
            }
        case .intro(let phraseIndex):
            PhraseAccessIntro(
                ownerState: ownerState,
                session: session,
                onReadyToGetStarted: {
                    self.step = .retrievingShards(phraseIndex: phraseIndex)
                }
            )
            .navigationTitle(Text("Access"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        self.step = .showingList
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                    }
                }
            })
        case .retrievingShards(let phraseIndex):
            RetrieveRecoveredShards(
                session: session,
                ownerState: ownerState,
                onSuccess: { encryptedShards in
                    do {
                        self.step = .showingSeedPhrase(phraseIndex: phraseIndex, phrase: try recoverSecret(encryptedShards, phraseIndex), start: Date.now)
                    } catch {
                        self.step = .showingList
                        showError(CensoError.failedToDecryptSecrets)
                    }
                },
                onCancelled: {
                    self.step = .showingList
                }
            )
        case .showingSeedPhrase(let phraseIndex, let phrase, let start):
            let label = ownerState.vault.secrets[phraseIndex].label
            ShowPhrase(
                label: label,
                words: phrase,
                onComplete: { finished in
                    if finished {
                        viewedPhrases.append(phraseIndex)
                    }
                    self.step = .showingList
                },
                start: start
            )
            .navigationTitle(Text(label))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .interactiveDismissDisabled()
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        self.step = .showingList
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.black)
                    }
                }
            })
        }
    }
    
    private func showError(_ error: Error) {
        self.showingError = true
        self.error = error
    }
    
    private func recoverSecret(_ encryptedShards: [API.EncryptedShard], _ phraseIndex: Int) throws -> [String] {
        do {
            let intermediateKey = try EncryptionKey.recover(encryptedShards, session)
            let masterKey = try EncryptionKey.generateFromPrivateKeyRaw(data: try intermediateKey.decrypt(base64EncodedString: ownerState.policy.encryptedMasterKey))
            let decryptedSecret = try masterKey.decrypt(base64EncodedString:ownerState.vault.secrets[phraseIndex].encryptedSeedPhrase)
            return try BIP39.binaryDataToWords(binaryData: decryptedSecret)
        } catch {
            RaygunClient.sharedInstance().send(error: error, tags: ["Access"], customData: nil)
            throw error
        }
   }
}
