//
//  ApproversSetup.swift
//  Vault
//
//  Created by Anton Onyshchenko on 19.10.23.
//

import Foundation
import SwiftUI
import Moya
import raygun4apple

struct ApproversSetup: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss
    
    var session: Session
    var ownerState: API.OwnerState.Ready
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    
    enum Step {
        case setupPrimary
        case proposeAlternate
        case setupAlternate
        case requestingRecovery
        case retrievingShards
        case replacingPolicy
        case done
        
        static func fromOwnerState(_ ownerState: API.OwnerState.Ready) -> Step {
            if ownerState.policySetup?.alternateApprover == nil {
                if ownerState.policySetup?.primaryApprover?.isConfirmed == true {
                    return .proposeAlternate
                } else {
                    return .setupPrimary
                }
            } else {
                return .setupAlternate
            }
        }
    }
    
    @State private var step: Step
    @State private var proposeToAddAlternateApprover = false
    @State private var showingError = false
    @State private var error: Error?
    
    init(session: Session, ownerState: API.OwnerState.Ready, onOwnerStateUpdated: @escaping (API.OwnerState) -> Void, step: Step) {
        self.session = session
        self.ownerState = ownerState
        self.onOwnerStateUpdated = onOwnerStateUpdated
        self._step = State(initialValue: step)
    }
    
    init(session: Session, ownerState: API.OwnerState.Ready, onOwnerStateUpdated: @escaping (API.OwnerState) -> Void) {
        self.session = session
        self.ownerState = ownerState
        self.onOwnerStateUpdated = onOwnerStateUpdated
        self._step = State(initialValue: Step.fromOwnerState(ownerState))
    }
    
    var body: some View {
        switch (step) {
        case .setupPrimary:
            SetupApprover(
                session: session,
                policySetup: ownerState.policySetup,
                isPrimary: true,
                onComplete: {
                    step = .proposeAlternate
                },
                onOwnerStateUpdated: onOwnerStateUpdated
            )
        case .proposeAlternate:
            ProposeToAddAlternateApprover(
                onAccept: {
                    step = .setupAlternate
                },
                onSkip: {
                    initPolicyReplacement()
                }
            )
        case .setupAlternate:
            SetupApprover(
                session: session,
                policySetup: ownerState.policySetup,
                isPrimary: false,
                onComplete: {
                    initPolicyReplacement()
                },
                onOwnerStateUpdated: onOwnerStateUpdated
            )
        case .requestingRecovery, .replacingPolicy:
            ProgressView()
                .navigationBarTitleDisplayMode(.inline)
                .alert("Error", isPresented: $showingError, presenting: error) { _ in
                    Button {
                        showingError = false
                        error = nil
                        self.step = Step.fromOwnerState(ownerState)
                    } label: {
                        Text("OK")
                    }
                } message: { error in
                    Text(error.localizedDescription)
                }
        case .retrievingShards:
            FacetecAuth<API.RetrieveRecoveryShardsApiResponse>(
                session: session,
                onReadyToUploadResults: { biomentryVerificationId, biometryData in
                    return .retrieveRecoveredShards(API.RetrieveRecoveryShardsApiRequest(
                        biometryVerificationId: biomentryVerificationId,
                        biometryData: biometryData
                    ))
                },
                onSuccess: { response in
                    replacePolicy(response.encryptedShards)
                },
                onCancelled: {
                    dismiss()
                }
            )
        case .done:
            SavedAndSharded(
                secrets: ownerState.vault.secrets,
                approvers: ownerState.policy.guardians
            )
            .onAppear(perform: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    dismiss()
                }
            })
        }
    }
    
    private func showError(_ error: Error) {
        self.showingError = true
        self.error = error
    }
    
    private func requestRecovery(onSuccess: @escaping () -> Void) {
        apiProvider.decodableRequest(
            with: session,
            endpoint: .requestRecovery
        ) { (result: Result<API.OwnerStateResponse, MoyaError>) in
            switch result {
            case .success(let success):
                onOwnerStateUpdated(success.ownerState)
                onSuccess()
            case .failure(let error):
                showError(error)
            }
        }
    }
    
    private func deleteRecoveryIfExists(onSuccess: @escaping () -> Void) {
        if ownerState.recovery != nil {
            apiProvider.decodableRequest(
                with: session,
                endpoint: .deleteRecovery
            ) { (result: Result<API.OwnerStateResponse, MoyaError>) in
                switch result {
                case .success(let success):
                    onOwnerStateUpdated(success.ownerState)
                    onSuccess()
                case .failure(let error):
                    showError(error)
                }
            }
        } else {
            onSuccess()
        }
    }
    
    private func initPolicyReplacement() {
        self.step = .requestingRecovery
        
        // delete an ongoing recovery first if any
        // this is needed to allow a retry in case any subsequent API calls fail
        deleteRecoveryIfExists(onSuccess: {
            requestRecovery(onSuccess: {
                self.step = .retrievingShards
            })
        })
    }
    
    private func replacePolicy(_ encryptedShards: [API.RetrieveRecoveryShardsApiResponse.EncryptedShard]) {
        self.step = .replacingPolicy
        deleteRecoveryIfExists(onSuccess: {
            do {
                let policySetup = ownerState.policySetup!
                let ownerOldParticipantId = ownerState.policy.guardians.first!.participantId
        
                let newIntermediateKey = try EncryptionKey.generateRandomKey()
                let oldIntermediateKey = try EncryptionKey.recover(encryptedShards, session)
                let masterKey = try EncryptionKey.fromEncryptedPrivateKey(ownerState.policy.encryptedMasterKey, oldIntermediateKey)
                
                apiProvider.decodableRequest(
                    with: session,
                    endpoint: .replacePolicy(API.ReplacePolicyApiRequest(
                        intermediatePublicKey: try newIntermediateKey.publicExternalRepresentation(),
                        guardianShards: try newIntermediateKey.shard(
                            threshold: 2,
                            participants: policySetup.guardians.map({ approver in
                                return (approver.participantId, approver.publicKey!)
                            })
                        ),
                        encryptedMasterPrivateKey: try newIntermediateKey.encrypt(data: masterKey.privateKeyRaw()),
                        masterEncryptionPublicKey: try masterKey.publicExternalRepresentation(),
                        signatureByPreviousIntermediateKey: try oldIntermediateKey.signature(for: newIntermediateKey.publicKeyData())
                    ))
                ) { (result: Result<API.OwnerStateResponse, MoyaError>) in
                    switch result {
                    case .success(let response):
                        session.deleteApproverKey(participantId: ownerOldParticipantId)
                        self.step = .done
                        onOwnerStateUpdated(response.ownerState)
                    case .failure(let error):
                        showError(error)
                    }
                }
            } catch {
                RaygunClient.sharedInstance().send(error: error, tags: ["Replace policy"], customData: nil)
                showError(CensoError.failedToReplacePolicy)
            }
        })
    }
}

#if DEBUG
#Preview {
    NavigationView {
        ApproversSetup(
            session: Session.sample,
            ownerState: API.OwnerState.Ready(
                policy: .sample,
                vault: .sample,
                guardianSetup: policySetup
            ),
            onOwnerStateUpdated: { _ in }
        )
    }
}
#endif
