//
//  AccessPhrases.swift
//  Censo
//
//  Created by Brendan Flood on 10/25/23.
//

import SwiftUI
import Moya
import raygun4apple

struct AccessPhrases: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss
    
    var session: Session
    var ownerState: API.OwnerState.Ready
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    
    @State private var deletingRecovery = false
    @State private var showingError = false
    @State private var error: Error?
    
    var body: some View {
        NavigationView {
            if deletingRecovery {
                ProgressView()
                    .alert("Error", isPresented: $showingError, presenting: error) { _ in
                        Button {
                            dismiss()
                        } label: {
                            Text("OK")
                        }
                    }
            } else {
                switch (ownerState.recovery) {
                case nil:
                    ProgressView()
                        .onAppear {
                            requestRecovery()
                        }
                        .alert("Error", isPresented: $showingError, presenting: error) { _ in
                            Button {
                                dismiss()
                            } label: {
                                Text("OK")
                            }
                        }
                case .anotherDevice:
                    Text("An access request is in progress on another device")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar(content: {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button {
                                    dismiss()
                                } label: {
                                    Image(systemName: "xmark")
                                        .foregroundColor(.black)
                                }
                            }
                        })
                case .thisDevice(let recovery):
                    // delete it in case this is a leftover recovery from a policy replacement
                    if recovery.intent == .replacePolicy {
                        ProgressView()
                            .onAppear {
                                deleteRecovery(dismissOnSuccess: false)
                            }
                    } else {
                        switch (recovery.status) {
                        case .requested:
                            AccessApproval(
                                session: session,
                                policy: ownerState.policy,
                                recovery: recovery,
                                onCancel: deleteRecovery,
                                onOwnerStateUpdated: onOwnerStateUpdated
                            )
                        case .timelocked:
                            Text("Timelocked")
                                .navigationBarTitleDisplayMode(.inline)
                                .toolbar(content: {
                                    ToolbarItem(placement: .navigationBarLeading) {
                                        Button {
                                            dismiss()
                                        } label: {
                                            Image(systemName: "xmark")
                                                .foregroundColor(.black)
                                        }
                                    }
                                })
                        case .available:
                            AvailableRecovery(
                                session: session,
                                ownerState: ownerState,
                                recovery: recovery,
                                onFinished: deleteRecovery,
                                onOwnerStateUpdated: onOwnerStateUpdated
                            )
                        }
                    }
                }
            }
        }
    }
    
    private func requestRecovery() {
        apiProvider.decodableRequest(
            with: session,
            endpoint: .requestRecovery(API.RequestRecoveryApiRequest(intent: .accessPhrases))
        ) { (result: Result<API.OwnerStateResponse, MoyaError>) in
            switch result {
            case .success(let response):
                onOwnerStateUpdated(response.ownerState)
            case .failure(let error):
                showError(error)
            }
        }
    }
    
    private func deleteRecovery() {
        deleteRecovery(dismissOnSuccess: true)
    }
    
    private func deleteRecovery(dismissOnSuccess: Bool) {
        self.deletingRecovery = true
        apiProvider.decodableRequest(with: session, endpoint: .deleteRecovery) { (result: Result<API.DeleteRecoveryApiResponse, MoyaError>) in
            switch result {
            case .success(let response):
                onOwnerStateUpdated(response.ownerState)
                if dismissOnSuccess {
                    dismiss()
                }
            case .failure(let error):
                self.showingError = true
                self.error = error
            }
        }
    }
    
    private func showError(_ error: Error) {
        self.showingError = true
        self.error = error
    }
}

struct AvailableRecovery: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss
    
    var session: Session
    var ownerState: API.OwnerState.Ready
    var recovery: API.Recovery.ThisDevice
    var onFinished: () -> Void
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    
    enum Step {
        case showingList
        case intro(phraseIndex: Int)
        case retrievingShards(phraseIndex: Int)
        case showingSeedPhrase(phraseIndex: Int, phrase: [String])
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
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        onFinished()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.black)
                    }
                }
            })
            .alert("Error", isPresented: $showingError, presenting: error) { _ in
                Button {
                } label: {
                    Text("OK")
                }
            } message: { error in
                Text(error.localizedDescription)
            }
        case .intro(let phraseIndex):
            AccessIntro(
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
            switch ownerState.authType {
            case .none:
                EmptyView().onAppear {
                    self.step = .showingList
                }
            case .facetec:
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
            case .password:
                GetPassword { cryptedPassword, onComplete in
                    apiProvider.decodableRequest(with: session, endpoint: .retrieveRecoveredShardsWithPassword(API.RetrieveRecoveryShardsWithPasswordApiRequest(password: API.Password(cryptedPassword: cryptedPassword)))) { (result: Result<API.RetrieveRecoveryShardsWithPasswordApiResponse, MoyaError>) in
                        switch result {
                        case .success(let response):
                            do {
                                self.step = .showingSeedPhrase(phraseIndex: phraseIndex, phrase: try recoverSecret(response.encryptedShards, phraseIndex))
                            } catch {
                                self.step = .showingList
                                showError(CensoError.failedToDecryptSecrets)
                            }
                            onComplete(true)
                        case .failure(MoyaError.underlying(CensoError.validation("Incorrect password"), _)):
                            onComplete(false)
                        case .failure:
                            self.step = .showingList
                            onComplete(true)
                        }
                    }
                    
                }
            }
        case .showingSeedPhrase(let phraseIndex, let phrase):
            let label = ownerState.vault.secrets[phraseIndex].label
            ShowPhrase(
                label: label,
                words: phrase,
                onComplete: { finished in
                    if finished {
                        viewedPhrases.append(phraseIndex)
                    }
                    self.step = .showingList
                }
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

#if DEBUG
#Preview {
    AccessPhrases(
        session: .sample,
        ownerState: API.OwnerState.Ready(policy: .sample, vault: .sample, authType: .facetec),
        onOwnerStateUpdated: {_ in}
    )
}
#endif
