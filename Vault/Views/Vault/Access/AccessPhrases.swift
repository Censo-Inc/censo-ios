//
//  AccessPhrases.swift
//  Vault
//
//  Created by Brendan Flood on 10/25/23.
//

import SwiftUI
import Moya

struct AccessPhrases: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss
    
    var session: Session
    var ownerState: API.OwnerState.Ready
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    
    enum Step {
        case initial
        case creatingAccessRequest
        case cancellingAccessRequest
        case showingList
        case otherDevice
        case intro(phraseIndex: Int)
        case retrievingShards(phraseIndex: Int)
        case showingSeedPhrase(phraseIndex: Int, phrase: [String])
        case done
        
        static func fromOwnerState(_ ownerState: API.OwnerState.Ready) -> Step {
            if let recovery = ownerState.recovery {
                if recovery.isThisDevice {
                    return .showingList
                } else {
                    return .otherDevice
                }
            } else {
                return .initial
            }
        }
    }
    
    @State private var step: Step
    @State private var viewedPhrases: [Int] = []
    @State private var showingError = false
    @State private var error: Error?
    
    init(session: Session, ownerState: API.OwnerState.Ready, onOwnerStateUpdated: @escaping (API.OwnerState) -> Void) {
        self.session = session
        self.ownerState = ownerState
        self.onOwnerStateUpdated = onOwnerStateUpdated
        self._step = State(initialValue: Step.fromOwnerState(ownerState))
    }
    
    var body: some View {
        VStack {
            switch (step) {
            case .initial:
                if ownerState.policy.guardians.count == 1 {
                    ProgressView().onAppear {
                        requestRecovery()
                    }
                }
            case .creatingAccessRequest,
                    .cancellingAccessRequest:
                ProgressView()
            case .otherDevice:
                Text("There is a recovery in progress on another device")
            case .showingList:
                ShowPhraseList(
                    session: session,
                    ownerState: ownerState,
                    onOwnerStateUpdated: onOwnerStateUpdated,
                    viewedPhrases: viewedPhrases,
                    onPhraseSelected: { selectedPhraseIndex in
                        self.step = .intro(phraseIndex: selectedPhraseIndex)
                    },
                    onFinished: {
                        cancelRecovery()
                    }
                )
            case .intro(let phraseIndex):
                AccessIntro(
                    ownerState: ownerState,
                    session: session,
                    onReadyToGetStarted: {
                        self.step = .retrievingShards(phraseIndex: phraseIndex)
                    }
                )
            case .retrievingShards(let phraseIndex):
                FacetecAuth<API.RetrieveRecoveryShardsApiResponse>(
                    session: session,
                    onReadyToUploadResults: { biomentryVerificationId, biometryData in
                        return .retrieveRecoveredShards(API.RetrieveRecoveryShardsApiRequest(
                            biometryVerificationId: biomentryVerificationId,
                            biometryData: biometryData
                        ))
                    },
                    onSuccess: { response in
                        do {
                            self.step = .showingSeedPhrase(phraseIndex: phraseIndex, phrase: try recoverSecret(response.encryptedShards, phraseIndex))
                        } catch {
                            self.step = .showingList
                            showError(CensoError.failedToDecryptSecrets)
                        }
                    },
                    onCancelled: {
                        self.step = .showingList
                    }
                )
            case .showingSeedPhrase(let phraseIndex, let phrase):
                NavigationView {
                    ShowPhrase(
                        label: ownerState.vault.secrets[phraseIndex].label,
                        words: phrase,
                        onComplete: { finished in
                            if finished {
                                viewedPhrases.append(phraseIndex)
                            }
                            self.step = .showingList
                        }
                    )
                }
            case .done:
                EmptyView()
                    .onAppear{
                        dismiss()
                    }
            }
        }
        .alert("Error", isPresented: $showingError, presenting: error) { _ in
            Button {
                showingError = false
                error = nil
            } label: {
                Text("OK")
            }
        }
    }
    
    private func requestRecovery() {
        self.step = .creatingAccessRequest
        apiProvider.decodableRequest(
            with: session,
            endpoint: .requestRecovery(API.RequestRecoveryApiRequest(intent: .accessPhrases))
        ) { (result: Result<API.OwnerStateResponse, MoyaError>) in
            switch result {
            case .success(let response):
                onOwnerStateUpdated(response.ownerState)
                self.step = .showingList
            case .failure(let error):
                showError(error)
                self.step = .initial
            }
        }
    }
    
    private func cancelRecovery() {
        self.step = .cancellingAccessRequest
        apiProvider.decodableRequest(with: session, endpoint: .deleteRecovery) { (result: Result<API.DeleteRecoveryApiResponse, MoyaError>) in
            switch result {
            case .success(let response):
                onOwnerStateUpdated(response.ownerState)
                dismiss()
            case .failure(let error):
                self.showingError = true
                self.error = error
                self.step = .showingList
            }
        }
    }
    
    private func showError(_ error: Error) {
        self.showingError = true
        self.error = error
    }
    
    private func recoverSecret(_ encryptedShards: [API.RetrieveRecoveryShardsApiResponse.EncryptedShard], _ phraseIndex: Int) throws -> [String] {
        let intermediateKey = try EncryptionKey.recover(encryptedShards, session)
        let masterKey = try EncryptionKey.generateFromPrivateKeyRaw(data: try intermediateKey.decrypt(base64EncodedString: ownerState.policy.encryptedMasterKey))
        let decryptedSecret = try masterKey.decrypt(base64EncodedString:ownerState.vault.secrets[phraseIndex].encryptedSeedPhrase)
        return try BIP39.binaryDataToWords(binaryData: decryptedSecret)
   }
}

#if DEBUG
#Preview {
    AccessPhrases(
        session: .sample,
        ownerState: API.OwnerState.Ready(policy: .sample, vault: .sample),
        onOwnerStateUpdated: {_ in}
    )
}
#endif
