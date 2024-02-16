//
//  OwnerKeyRecovery.swift
//  Censo
//
//  Created by Anton Onyshchenko on 10.01.24.
//

import Foundation
import SwiftUI
import Moya
import Sentry

struct OwnerKeyRecovery: View {
    @EnvironmentObject var ownerRepository: OwnerRepository
    @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController
    
    var ownerState: API.OwnerState.Ready
    
    @State private var step: Step = .requestingAccess
    @State private var showSheet: Bool = false
    @State private var showingError = false
    @State private var error: Error?
    
    enum Step {
        case requestingAccess
        case recoveringKey(encryptedShards: [API.EncryptedShard])
        case recovered(ownerState: API.OwnerState)
        case cleanup
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                LoginIdResetCollectTokensStep(
                    enabled: false,
                    tokens: Binding.constant([])
                )
                
                LoginIdResetSignInStep(
                    enabled: false,
                    onSuccess: {}
                )
                
                LoginIdResetStartVerificationStep(
                    enabled: false,
                    ownerRepository: ownerRepository,
                    tokens: Binding.constant([]),
                    onDeviceCreated: {}
                )
                
                LoginIdResetInitKeyRecoveryStep(
                    enabled: true,
                    loggedIn: true,
                    onButtonPressed: {
                        showSheet = true
                    }
                )
            }
            .padding(.top)
            .padding(.horizontal)
            .sheet(isPresented: $showSheet) {
                NavigationView {
                    switch (step) {
                    case .requestingAccess:
                        RequestAccess(
                            ownerState: ownerState,
                            intent: .recoverOwnerKey,
                            accessAvailableView: { _ in
                                RetrieveAccessShards(
                                    ownerState: ownerState,
                                    onSuccess: { encryptedShards in
                                        self.step = .recoveringKey(encryptedShards: encryptedShards)
                                    },
                                    onCancelled: {
                                        self.step = .cleanup
                                    }
                                )
                            }
                        )
                    case .recoveringKey(let encryptedShards):
                        ProgressView("Recovering key")
                            .onAppear {
                                recoverOwnerApproverKey(encryptedShards)
                            }
                            .errorAlert(isPresented: $showingError, presenting: error) {
                                self.step = .cleanup
                            }
                    case .recovered(let ownerState):
                        VStack {
                            ZStack {
                                Image("AccessApproved")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .padding(.top)
                                
                                VStack(alignment: .center) {
                                    Spacer()
                                    Text("You are all set!")
                                        .font(.system(size: UIFont.textStyleSize(.largeTitle) * 1.5, weight: .medium))
                                    Spacer()
                                }
                            }
                        }
                        .frame(maxHeight: .infinity)
                        .navigationBarTitleDisplayMode(.inline)
                        .onAppear(perform: {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                ownerStateStoreController.replace(ownerState)
                            }
                        })
                    case .cleanup:
                        ProgressView()
                            .onAppear {
                                deleteAccessIfExists(onSuccess: {
                                    showSheet = false
                                })
                            }
                            .errorAlert(isPresented: $showingError, presenting: error) {
                                self.showSheet = false
                            }
                    }
                }
            }
        }
    }
    
    private func recoverOwnerApproverKey(_ encryptedShards: [API.EncryptedShard]) {
        deleteAccessIfExists(onSuccess: {
            do {
                let ownerParticipantId = ownerState.policy.owner!.participantId
                let ownerEntropy = ownerState.policy.ownerEntropy?.data
                let shardsWithoutOwner = encryptedShards.filter({ !$0.isOwnerShard })
                
                let intermediateKey = try EncryptionKey.recover(
                    shardsWithoutOwner,
                    ownerRepository.userIdentifier,
                    ownerRepository.deviceKey
                )
                
                if !(try intermediateKey.verifySignature(
                    for: encryptedShards
                        .filter({ $0.approverPublicKey != nil })
                        .map({ $0.approverPublicKey! })
                        .sortedByStringRepr()
                        .toBytes(),
                    signature: ownerState.policy.approverKeysSignatureByIntermediateKey
                )) {
                    throw CensoError.failedToRecoverPrivateKey
                }
                
                let newIntermediateKey = try EncryptionKey.generateRandomKey()
                let newOwnerApproverKey = try ownerRepository.generateApproverKey()
                let masterKey = try EncryptionKey.fromEncryptedPrivateKey(ownerState.policy.encryptedMasterKey, intermediateKey)
                let masterPublicKey = try masterKey.publicExternalRepresentation()
                
                let participants = shardsWithoutOwner
                    .filter({ $0.approverPublicKey != nil })
                    .map({ ($0.participantId, $0.approverPublicKey! )})
                + [(
                    ownerParticipantId,
                    try newOwnerApproverKey.publicExternalRepresentation()
                )]
                
                let concatenatedApproverPublicKeys = participants
                    .map({ (_, publicKey) in publicKey })
                    .sortedByStringRepr()
                    .toBytes()
                
                ownerRepository.replacePolicyShards(
                    API.ReplacePolicyShardsApiRequest(
                        intermediatePublicKey: try newIntermediateKey.publicExternalRepresentation(),
                        approverPublicKeysSignatureByIntermediateKey: try newIntermediateKey.signature(for: concatenatedApproverPublicKeys),
                        approverShards: try newIntermediateKey.shard(
                            threshold: Int(ownerState.policy.threshold),
                            participants: participants
                        ).map({
                            return API.ReplacePolicyShardsApiRequest.ApproverShard(
                                participantId: $0.participantId,
                                encryptedShard: $0.shard,
                                approverPublicKey: $0.participantPublicKey
                            )
                        }),
                        encryptedMasterPrivateKey: try newIntermediateKey.encrypt(data: masterKey.privateKeyRaw()),
                        masterEncryptionPublicKey: masterPublicKey,
                        signatureByPreviousIntermediateKey: try intermediateKey.signature(for: newIntermediateKey.publicKeyData()),
                        masterKeySignature: try newOwnerApproverKey.signature(for: masterPublicKey.data)
                    ),
                    { result in
                        switch result {
                        case .success(let response):
                            do {
                                try ownerRepository.persistApproverKey(keyId: ownerParticipantId, key: newOwnerApproverKey, entropy: ownerEntropy)
                                step = .recovered(ownerState: response.ownerState)
                            } catch {
                                SentrySDK.captureWithTag(error: error, tagValue: "Owners approver key recovery")
                                showError(CensoError.failedToPersistApproverKey)
                                
                                ownerRepository.deleteApproverKey(keyId: ownerParticipantId)
                                self.step = .cleanup
                            }
                        case .failure(let error):
                            showError(error)
                        }
                    }
                )
            } catch {
                SentrySDK.captureWithTag(error: error, tagValue: "Owners approver key recovery")
                showError(CensoError.failedToRecoverPrivateKey)
            }
        })
    }
    
    private func deleteAccessIfExists(onSuccess: @escaping () -> Void) {
        if ownerState.access != nil {
            ownerRepository.deleteAccess({ result in
                switch result {
                case .success(let success):
                    ownerStateStoreController.replace(success.ownerState)
                    onSuccess()
                case .failure(let error):
                    showError(error)
                }
            })
        } else {
            onSuccess()
        }
    }
    
    private func showError(_ error: Error) {
        self.showingError = true
        self.error = error
    }
}
