//
//  ImplicitOwnerPlanSetup.swift
//  Censo
//
//  Created by Brendan Flood on 10/10/23.
//

import SwiftUI
import Moya

struct InitialPlanSetup: View {
    @Environment(\.dismiss) var dismiss
    
    var session: Session
    var onComplete: (API.OwnerState) -> Void
    
    var participantId: ParticipantId = .random()
    
    @State private var showingError = false
    @State private var error: Error?

    struct CreatePolicyParams {
        var guardianPublicKey: Base58EncodedPublicKey
        var intermediatePublicKey: Base58EncodedPublicKey
        var masterEncryptionPublicKey: Base58EncodedPublicKey
        var encryptedMasterPrivateKey: Base64EncodedString
        var encryptedShard: Base64EncodedString
    }
    
    @State private var createPolicyParams: CreatePolicyParams?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let createPolicyParams {
                FacetecAuth<API.CreatePolicyApiResponse>(session: session) { verificationId, facetecBiometry in
                        .createPolicy(
                            API.CreatePolicyApiRequest(
                                intermediatePublicKey: createPolicyParams.intermediatePublicKey,
                                encryptedMasterPrivateKey: createPolicyParams.encryptedMasterPrivateKey,
                                masterEncryptionPublicKey: createPolicyParams.masterEncryptionPublicKey,
                                participantId: participantId,
                                encryptedShard: createPolicyParams.encryptedShard,
                                guardianPublicKey: createPolicyParams.guardianPublicKey,
                                biometryVerificationId: verificationId,
                                biometryData: facetecBiometry
                            )
                        )
                } onSuccess: { response in
                    onComplete(response.ownerState)
                } onCancelled: {
                    dismiss()
                }
            } else {
                Image("LargeFaceScan")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 298, maxHeight: 200)
                    .saturation(0.0)

                VStack(alignment: .leading) {
                    Spacer()
                   
                    Text("Scan your face")
                        .font(.title2)
                        .bold()
                        .padding()
                    
                    VStack(alignment: .leading) {
                        Text("Your face scan ensures that only you have access to your seed phrase.")
                            .font(.subheadline)
                            .padding(.bottom, 1)
                        
                        Text("You will capture and store an encrypted 3D map of your face to confirm your live physical presence.")
                            .font(.subheadline)
                            .padding(.bottom, 1)
                    }
                    .padding()
                    
                    Button {
                        startPolicyCreation()
                    } label: {
                        HStack {
                            Spacer()
                            Image("FaceScanBW")
                                .resizable()
                                .frame(width: 36, height: 36)
                            Text("Begin face scan")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .buttonStyle(RoundedButtonStyle())
                    .padding()
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
        }
        .padding()
        .navigationTitle(Text(""))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                BackButton()
            }
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
            Text("There was an error submitting your info.\n\(error.localizedDescription)")
        }
    }
    
    private func showError(_ error: Error) {
        self.error = error
        self.showingError = true
    }
    
    private func startPolicyCreation() {
        do {
            let ownerApproverPublicKey = try session.getOrCreateApproverKey(participantId: participantId).publicExternalRepresentation()
            let intermediateEncryptionKey = try EncryptionKey.generateRandomKey()
            let masterEncryptionKey = try EncryptionKey.generateRandomKey()
            
            createPolicyParams = CreatePolicyParams(
                guardianPublicKey: ownerApproverPublicKey,
                intermediatePublicKey: try intermediateEncryptionKey.publicExternalRepresentation(),
                masterEncryptionPublicKey: try masterEncryptionKey.publicExternalRepresentation(),
                encryptedMasterPrivateKey: try intermediateEncryptionKey.encrypt(data: masterEncryptionKey.privateKeyRaw()),
                encryptedShard: try intermediateEncryptionKey.shard(
                    threshold: 1,
                    participants: [(participantId, ownerApproverPublicKey)]
                ).first(where: { $0.participantId == participantId })!.encryptedShard
            )
        } catch {
            showError(error)
        }
    }
}

#if DEBUG
#Preview {
    NavigationView {
        InitialPlanSetup(session: .sample, onComplete: {_ in})
    }
}
#endif
