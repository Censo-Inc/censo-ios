//
//  InitialPolicySetup.swift
//  Censo
//
//  Created by Brendan Flood on 10/10/23.
//

import SwiftUI
import Moya

struct InitialPolicySetup: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var ownerRepository: OwnerRepository
    @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController

    var ownerState: API.OwnerState.Initial
    var onCancel: () -> Void
    
    @State private var showingError = false
    @State private var error: Error?

    struct CreatePolicyParams {
        var approverPublicKey: Base58EncodedPublicKey
        var approverPublicKeySignatureByIntermediateKey: Base64EncodedString
        var intermediatePublicKey: Base58EncodedPublicKey
        var masterEncryptionPublicKey: Base58EncodedPublicKey
        var encryptedMasterPrivateKey: Base64EncodedString
        var encryptedShard: Base64EncodedString
        var participantId: ParticipantId
        var masterKeySignature: Base64EncodedString
        var entropy: Base64EncodedString
    }
    
    @State private var createPolicyParams: CreatePolicyParams?

    var body: some View {
        VStack {
            AuthEnrollmentView(
                onStartEnrollment: startPolicyCreation,
                onPasswordReady: { cryptedPassword in
                    if let createPolicyParams {
                        ownerRepository.createPassword(API.CreatePolicyWithPasswordApiRequest(
                            intermediatePublicKey: createPolicyParams.intermediatePublicKey,
                            encryptedMasterPrivateKey: createPolicyParams.encryptedMasterPrivateKey,
                            masterEncryptionPublicKey: createPolicyParams.masterEncryptionPublicKey,
                            participantId: createPolicyParams.participantId,
                            encryptedShard: createPolicyParams.encryptedShard,
                            approverPublicKey: createPolicyParams.approverPublicKey,
                            approverPublicKeySignatureByIntermediateKey: createPolicyParams.approverPublicKeySignatureByIntermediateKey,
                            password: API.Authentication.Password(cryptedPassword: cryptedPassword),
                            masterKeySignature: createPolicyParams.masterKeySignature
                        )) { result in
                            switch result {
                            case .failure(let error):
                                showError(error)
                            case .success(let response):
                                ownerStateStoreController.replace(response.ownerState)
                            }
                        }
                    } else {
                        dismiss()
                        showError(CensoError.invalidPolicySetup)
                    }
                },
                onFaceScanReady: { facetecBiometry, completion in
                    if let createPolicyParams {
                        ownerRepository.createPolicy(
                            API.CreatePolicyApiRequest(
                                intermediatePublicKey: createPolicyParams.intermediatePublicKey,
                                encryptedMasterPrivateKey: createPolicyParams.encryptedMasterPrivateKey,
                                masterEncryptionPublicKey: createPolicyParams.masterEncryptionPublicKey,
                                participantId: createPolicyParams.participantId,
                                encryptedShard: createPolicyParams.encryptedShard,
                                approverPublicKey: createPolicyParams.approverPublicKey,
                                approverPublicKeySignatureByIntermediateKey: createPolicyParams.approverPublicKeySignatureByIntermediateKey,
                                biometryVerificationId: facetecBiometry.verificationId,
                                biometryData: facetecBiometry,
                                masterKeySignature: createPolicyParams.masterKeySignature
                            ),
                            completion
                        )
                    } else {
                        dismiss()
                        showError(CensoError.invalidPolicySetup)
                    }
                },
                onFaceScanSuccess: { ownerState in
                    ownerStateStoreController.replace(ownerState)
                },
                onBiometryCanceled: {
                    self.createPolicyParams = nil
                },
                onCancel: onCancel,
                showAsBack: true
            )
        }
        .alert("Error", isPresented: $showingError, presenting: error) { _ in
            Button {
                showingError = false
                error = nil
                createPolicyParams = nil
            } label: {
                Text("OK")
            }
        } message: { error in
            Text(error.localizedDescription)
        }
    }
    
    private func showError(_ error: Error) {
        self.error = error
        self.showingError = true
    }
    
    private func startPolicyCreation() {
        do {
            let participantId: ParticipantId = .random()
            let ownerApproverKey = try ownerRepository.getOrCreateApproverKey(keyId: participantId, entropy: ownerState.entropy.data)
            let ownerApproverPublicKey = try ownerApproverKey.publicExternalRepresentation()
            let intermediateEncryptionKey = try EncryptionKey.generateRandomKey()
            let masterEncryptionKey = try EncryptionKey.generateRandomKey()
            let masterPublicKey = try masterEncryptionKey.publicExternalRepresentation()
            createPolicyParams = CreatePolicyParams(
                approverPublicKey: ownerApproverPublicKey,
                approverPublicKeySignatureByIntermediateKey: try intermediateEncryptionKey.signature(for: ownerApproverPublicKey.data),
                intermediatePublicKey: try intermediateEncryptionKey.publicExternalRepresentation(),
                masterEncryptionPublicKey: masterPublicKey,
                encryptedMasterPrivateKey: try intermediateEncryptionKey.encrypt(data: masterEncryptionKey.privateKeyRaw()),
                encryptedShard: try intermediateEncryptionKey.shard(
                    threshold: 1,
                    participants: [(participantId, ownerApproverPublicKey)]
                ).first(where: { $0.participantId == participantId })!.shard,
                participantId: participantId,
                masterKeySignature: try ownerApproverKey.signature(for: masterPublicKey.data),
                entropy: ownerState.entropy
            )
        } catch {
            dismiss()
            showError(error)
        }
    }
}

#if DEBUG
#Preview {
    LoggedInOwnerPreviewContainer {
        InitialPolicySetup(
            ownerState: API.OwnerState.Initial(authType: .none, entropy: .sample, subscriptionStatus: .active, subscriptionRequired: false),
            onCancel: {}
        )
    }
}
#endif
