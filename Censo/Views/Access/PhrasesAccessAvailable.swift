//
//  PhrasesAccessAvailable.swift
//  Censo
//
//  Created by Anton Onyshchenko on 30.11.23.
//

import Foundation
import SwiftUI
import Sentry

struct PhrasesAccessAvailable: View {
    @EnvironmentObject var ownerRepository: OwnerRepository
    
    var ownerState: API.OwnerState.Ready
    var onFinished: () -> Void
    
    enum Step {
        case showingList
        case intro(phraseIndex: Int)
        case retrievingSeedPhrase(phraseIndex: Int, language: WordListLanguage?)
        case retrievingShards(phraseIndex: Int, encryptedSeedPhrase: Base64EncodedString, language: WordListLanguage?)
        case showingSeedPhrase(phraseIndex: Int, seedPhrase: SeedPhrase, start: Date)
    }
    
    @State private var step: Step = .showingList
    @State private var viewedPhrases: [Int] = []
    @State private var showingError = false
    @State private var error: Error?
    
    var body: some View {
        switch (step) {
        case .showingList:
            ShowPhraseList(
                ownerState: ownerState,
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
            .errorAlert(isPresented: $showingError, presenting: error)
        case .intro(let phraseIndex):
            PhraseAccessIntro(
                ownerState: ownerState,
                onReadyToGetStarted: { language in
                    self.step = .retrievingSeedPhrase(phraseIndex: phraseIndex, language: language)
                }
            )
            .navigationInlineTitle("Access")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    DismissButton(icon: .back, action: {
                        self.step = .showingList
                    })
                }
            }
        case .retrievingSeedPhrase(let phraseIndex, let language):
            ProgressView()
                .onAppear {
                    getSeedPhrase(
                        phraseIndex: phraseIndex,
                        onEncryptedSeedPhraseRetrieved: { encryptedSeedPhrase in
                            self.step = .retrievingShards(
                                phraseIndex: phraseIndex,
                                encryptedSeedPhrase: encryptedSeedPhrase,
                                language: language
                            )
                        }
                    )
                }
                .errorAlert(isPresented: $showingError, presenting: error) {
                    self.step = .showingList
                }
        case .retrievingShards(let phraseIndex, let encryptedSeedPhrase, let language):
            RetrieveAccessShards(
                ownerState: ownerState,
                onSuccess: { encryptedShards in
                    do {
                        self.step = .showingSeedPhrase(
                            phraseIndex: phraseIndex,
                            seedPhrase: try recoverPhrase(encryptedShards, encryptedSeedPhrase, language),
                            start: Date.now)
                    } catch {
                        self.step = .showingList
                        showError(CensoError.failedToDecryptSecrets)
                    }
                },
                onCancelled: {
                    self.step = .showingList
                }
            )
        case .showingSeedPhrase(let phraseIndex, let seedPhrase, let start):
            let label = ownerState.vault.seedPhrases[phraseIndex].label
            ShowPhrase(
                label: label,
                seedPhrase: seedPhrase,
                onComplete: { finished in
                    if finished {
                        viewedPhrases.append(phraseIndex)
                    }
                    self.step = .showingList
                },
                start: start
            )
            .navigationInlineTitle(label)
            .interactiveDismissDisabled()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    DismissButton(icon: .close, action: {
                        self.step = .showingList
                    })
                }
            }
        }
    }
    
    private func showError(_ error: Error) {
        self.showingError = true
        self.error = error
    }
    
    func getSeedPhrase( phraseIndex: Int, onEncryptedSeedPhraseRetrieved: @escaping  (Base64EncodedString) -> Void) {
        ownerRepository.getSeedPhrase(ownerState.vault.seedPhrases[phraseIndex].guid) { result in
            switch result {
            case .success(let payload):
                onEncryptedSeedPhraseRetrieved(payload.encryptedSeedPhrase)
            case .failure(let error):
                showError(error)
            }
        }
    }
    
    private func recoverPhrase(_ encryptedShards: [API.EncryptedShard], _ encryptedSeedPhrase: Base64EncodedString, _ language: WordListLanguage?) throws -> SeedPhrase {
        do {
            let intermediateKey = try EncryptionKey.recover(encryptedShards, ownerRepository.userIdentifier, ownerRepository.deviceKey)
            let masterKey = try EncryptionKey.generateFromPrivateKeyRaw(data: try intermediateKey.decrypt(base64EncodedString: ownerState.policy.encryptedMasterKey))
            let decryptedPhraseData = try masterKey.decrypt(base64EncodedString: encryptedSeedPhrase)
            return try SeedPhrase.fromData(data: decryptedPhraseData, language: language)
        } catch {
            SentrySDK.captureWithTag(error: error, tagValue: "Access")
            throw error
        }
   }
}

