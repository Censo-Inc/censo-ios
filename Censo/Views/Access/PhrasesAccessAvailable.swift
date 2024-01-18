//
//  PhrasesAccessAvailable.swift
//  Censo
//
//  Created by Anton Onyshchenko on 30.11.23.
//

import Foundation
import SwiftUI
import Moya
import Sentry

struct PhrasesAccessAvailable: View {
    @Environment(\.apiProvider) var apiProvider
    
    var session: Session
    var ownerState: API.OwnerState.Ready
    var onFinished: () -> Void
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    
    enum Step {
        case showingList
        case intro(phraseIndex: Int)
        case retrievingSeedPhrase(phraseIndex: Int, language: WordListLanguage?)
        case retrievingShards(phraseIndex: Int, encryptedSeedPhrase: Base64EncodedString, language: WordListLanguage?)
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
                onReadyToGetStarted: { language in
                    self.step = .retrievingSeedPhrase(phraseIndex: phraseIndex, language: language)
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
                    }
                }
            })
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
                .alert("Error", isPresented: $showingError, presenting: error) { _ in
                    Button {
                        self.step = .showingList
                    } label: {
                        Text("OK")
                    }
                } message: { error in
                    Text(error.localizedDescription)
                }
        case .retrievingShards(let phraseIndex, let encryptedSeedPhrase, let language):
            RetrieveAccessShards(
                session: session,
                ownerState: ownerState,
                onSuccess: { encryptedShards in
                    do {
                        self.step = .showingSeedPhrase(
                            phraseIndex: phraseIndex,
                            phrase: try recoverPhrase(encryptedShards, encryptedSeedPhrase, language),
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
        case .showingSeedPhrase(let phraseIndex, let phrase, let start):
            let label = ownerState.vault.seedPhrases[phraseIndex].label
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
                    }
                }
            })
        }
    }
    
    private func showError(_ error: Error) {
        self.showingError = true
        self.error = error
    }
    
    func getSeedPhrase( phraseIndex: Int, onEncryptedSeedPhraseRetrieved: @escaping  (Base64EncodedString) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .getSeedPhrase(guid: ownerState.vault.seedPhrases[phraseIndex].guid)) { (result: Result<API.GetSeedPhraseApiResponse, MoyaError>) in
            switch result {
            case .success(let payload):
                onEncryptedSeedPhraseRetrieved(payload.encryptedSeedPhrase)
            case .failure(let error):
                showError(error)
            }
        }
    }
    
    private func recoverPhrase(_ encryptedShards: [API.EncryptedShard], _ encryptedSeedPhrase: Base64EncodedString, _ language: WordListLanguage?) throws -> [String] {
        do {
            let intermediateKey = try EncryptionKey.recover(encryptedShards, session)
            let masterKey = try EncryptionKey.generateFromPrivateKeyRaw(data: try intermediateKey.decrypt(base64EncodedString: ownerState.policy.encryptedMasterKey))
            let decryptedPhraseData = try masterKey.decrypt(base64EncodedString: encryptedSeedPhrase)
            return try BIP39.binaryDataToWords(binaryData: decryptedPhraseData, language: language)
        } catch {
            SentrySDK.captureWithTag(error: error, tagValue: "Access")
            throw error
        }
   }
}

