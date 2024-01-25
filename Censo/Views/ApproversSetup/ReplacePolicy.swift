//
//  ReplacePolicy.swift
//  Censo
//
//  Created by Anton Onyshchenko on 01.12.23.
//
import SwiftUI
import Moya
import Sentry

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
                        RetrieveAccessShards(
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
                        ProgressView("Activating approver\(policySetup.approvers.count > 2 ? "s" : "")")
                    case .removeApprovers:
                        ProgressView("Removing approvers")
                    }
                }
                .onAppear {
                    replacePolicy(encryptedShards)
                }
                .alert("Error", isPresented: $showingError, presenting: error) { _ in
                    Button {
                        step = .cleanup
                    } label: {
                        Text("OK")
                    }
                } message: { error in
                    Text(error.localizedDescription)
                }
            case .cleanup:
                ProgressView()
                    .onAppear {
                        deleteAccessIfExists(onSuccess: onCanceled)
                    }
                    .alert("Error", isPresented: $showingError, presenting: error) { _ in
                        Button {
                            onCanceled()
                        } label: {
                            Text("OK")
                        }
                    } message: { error in
                        Text(error.localizedDescription)
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
        deleteAccessIfExists(onSuccess: {
            do {
                guard let policySetup = ownerState.policySetup,
                      let policySetupOwner = policySetup.owner else {
                    throw CensoError.invalidPolicySetup
                }
                
                guard let entropy = policySetupOwner.entropy else {
                    throw CensoError.invalidEntropy
                }
                
                if !policySetup.approvers.allSatisfy( { verifyKeyConfirmationSignature(approver: $0) } ) {
                    throw CensoError.cannotVerifyKeyConfirmationSignature
                }
                
                let ownerOldParticipantId = ownerState.policy.approvers.first!.participantId
                
                let newIntermediateKey = try EncryptionKey.generateRandomKey()
                let oldIntermediateKey = try EncryptionKey.recover(encryptedShards, session)
                let masterKey = try EncryptionKey.fromEncryptedPrivateKey(ownerState.policy.encryptedMasterKey, oldIntermediateKey)
                let masterPublicKey = try masterKey.publicExternalRepresentation()
                let ownerApproverKey = try session.getOrCreateApproverKey(participantId: policySetupOwner.participantId, entropy: entropy.data)
                
                apiProvider.request(
                    with: session,
                    endpoint: .ownerCompletion(
                        API.CompleteOwnerApprovershipApiRequest(
                            participantId: policySetup.owner!.participantId,
                            approverPublicKey: try ownerApproverKey.publicExternalRepresentation()
                        )
                    )
                ) { ownerCompletionResult in
                    do {
                        switch ownerCompletionResult {
                        case .failure(let error):
                            showError(error)
                        case .success:
                            let concatenatedApproverPublicKeys = (
                                [try ownerApproverKey.publicExternalRepresentation()] +
                                policySetup
                                    .approvers
                                    .filter { switch $0.status {
                                    case .ownerAsApprover:
                                        false
                                    default:
                                        true
                                    }}
                                    .map({ $0.publicKey! })
                            )
                                .sortedByStringRepr()
                                .toBytes()
                            
                            apiProvider.decodableRequest(
                                with: session,
                                endpoint: .replacePolicy(API.ReplacePolicyApiRequest(
                                    intermediatePublicKey: try newIntermediateKey.publicExternalRepresentation(),
                                    approverPublicKeysSignatureByIntermediateKey: try newIntermediateKey.signature(for: concatenatedApproverPublicKeys),
                                    approverShards: try newIntermediateKey.shard(
                                        threshold: policySetup.threshold,
                                        participants: policySetup.approvers.map({ approver in
                                            return switch approver.status {
                                            case .ownerAsApprover:
                                                (approver.participantId, try ownerApproverKey.publicExternalRepresentation())
                                            default:
                                                (approver.participantId, approver.publicKey!)
                                            }
                                        })
                                    ).map({
                                        return API.ReplacePolicyApiRequest.ApproverShard(participantId: $0.participantId, encryptedShard: $0.shard)
                                    }),
                                    encryptedMasterPrivateKey: try newIntermediateKey.encrypt(data: masterKey.privateKeyRaw()),
                                    masterEncryptionPublicKey: masterPublicKey,
                                    signatureByPreviousIntermediateKey: try oldIntermediateKey.signature(for: newIntermediateKey.publicKeyData()),
                                    masterKeySignature: try ownerApproverKey.signature(for: masterPublicKey.data)
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
                        }
                    } catch {
                        SentrySDK.captureWithTag(error: error, tagValue: "Replace policy")
                        showError(CensoError.failedToReplacePolicy)
                    }
                }
            } catch {
                SentrySDK.captureWithTag(error: error, tagValue: "Replace policy")
                showError(CensoError.failedToReplacePolicy)
            }
        })
    }
    
    private func verifyKeyConfirmationSignature(approver: API.ProspectApprover) -> Bool {
        switch approver.status {
        case .confirmed(let confirmed):
            do {
                guard let participantIdData = approver.participantId.value.data(using: .hexadecimal),
                      let timeMillisData = String(confirmed.timeMillis).data(using: .utf8),
                      let base58DevicePublicKey = (try? session.deviceKey.publicExternalRepresentation())?.base58EncodedPublicKey(),
                      let devicePublicKey = try? EncryptionKey.generateFromPublicExternalRepresentation(base58PublicKey: base58DevicePublicKey) else {
                    return false
                }
                
                return try devicePublicKey.verifySignature(for: confirmed.approverPublicKey.data + participantIdData + timeMillisData, signature: confirmed.approverKeySignature)
            } catch {
                SentrySDK.captureWithTag(error: error, tagValue: "Replace policy")
            }
            return false
        case .ownerAsApprover:
            return true
        default:
            return false
        }
    }
    
    private func deleteAccessIfExists(onSuccess: @escaping () -> Void) {
        if ownerState.access != nil {
            apiProvider.decodableRequest(
                with: session,
                endpoint: .deleteAccess
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
