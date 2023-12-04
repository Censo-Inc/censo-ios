//
//  ReplacePolicy.swift
//  Censo
//
//  Created by Anton Onyshchenko on 01.12.23.
//
import SwiftUI
import Moya
import raygun4apple

struct ReplacePolicy: View {
    @Environment(\.apiProvider) var apiProvider
    
    var session: Session
    var ownerState: API.OwnerState.Ready
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    
    var onSuccess: (API.OwnerState) -> Void
    var onCanceled: () -> Void
    var intent: Intent
    
    enum Intent {
        case setupApprovers
        case removeApprovers
    }
    
    enum Step {
        case requestingAccess
        case replacingPolicy(encryptedShards: [API.EncryptedShard])
        case cleanup
    }
    
    @State private var step: Step = .requestingAccess
    @State private var showingError = false
    @State private var error: Error?
    
    var body: some View {
        if let policySetup = ownerState.policySetup {
            switch (step) {
            case .requestingAccess:
                RequestAccess(
                    session: session,
                    ownerState: ownerState,
                    onOwnerStateUpdated: onOwnerStateUpdated,
                    intent: .replacePolicy,
                    accessAvailableView: { _ in
                        RetrieveRecoveredShards(
                            session: session,
                            ownerState: ownerState,
                            onSuccess: { encryptedShards in
                                self.step = .replacingPolicy(encryptedShards: encryptedShards)
                            },
                            onCancelled: {
                                self.step = .cleanup
                            }
                        )
                    }
                )
            case .replacingPolicy(let encryptedShards):
                Group {
                    switch (intent) {
                    case .setupApprovers:
                        ProgressView("Activating approver\(policySetup.guardians.count > 2 ? "s" : "")")
                    case .removeApprovers:
                        ProgressView("Removing approvers")
                    }
                }
                .onAppear {
                    replacePolicy(encryptedShards)
                }
            case .cleanup:
                ProgressView()
                    .onAppear {
                        deleteRecoveryIfExists(onSuccess: onCanceled)
                    }
            }
        } else {
            EmptyView()
                .onAppear {
                    onCanceled()
                }
        }
    }
    
    private func replacePolicy(_ encryptedShards: [API.EncryptedShard]) {
        deleteRecoveryIfExists(onSuccess: {
            do {
                let policySetup = ownerState.policySetup!
                
                if !policySetup.guardians.allSatisfy( { verifyKeyConfirmationSignature(guardian: $0) } ) {
                    throw CensoError.cannotVerifyKeyConfirmationSignature
                }

                let ownerOldParticipantId = ownerState.policy.guardians.first!.participantId
        
                let newIntermediateKey = try EncryptionKey.generateRandomKey()
                let oldIntermediateKey = try EncryptionKey.recover(encryptedShards, session)
                let masterKey = try EncryptionKey.fromEncryptedPrivateKey(ownerState.policy.encryptedMasterKey, oldIntermediateKey)
                
                apiProvider.decodableRequest(
                    with: session,
                    endpoint: .replacePolicy(API.ReplacePolicyApiRequest(
                        intermediatePublicKey: try newIntermediateKey.publicExternalRepresentation(),
                        guardianShards: try newIntermediateKey.shard(
                            threshold: policySetup.threshold,
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
                        onSuccess(response.ownerState)
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
    
    private func verifyKeyConfirmationSignature(guardian: API.ProspectGuardian) -> Bool {
        switch guardian.status {
        case .confirmed(let confirmed):
            do {
                guard let participantIdData = guardian.participantId.value.data(using: .hexadecimal),
                      let timeMillisData = String(confirmed.timeMillis).data(using: .utf8),
                      let base58DevicePublicKey = (try? session.deviceKey.publicExternalRepresentation())?.base58EncodedPublicKey(),
                      let devicePublicKey = try? EncryptionKey.generateFromPublicExternalRepresentation(base58PublicKey: base58DevicePublicKey) else {
                    return false
                }
                
                return try devicePublicKey.verifySignature(for: confirmed.guardianPublicKey.data + participantIdData + timeMillisData, signature: confirmed.guardianKeySignature)
            } catch {
                RaygunClient.sharedInstance().send(error: error, tags: ["Replace policy"], customData: nil)
            }
            return false
        case .implicitlyOwner:
            return true
        default:
            return false
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
    
    private func showError(_ error: Error) {
        self.showingError = true
        self.error = error
    }
}
