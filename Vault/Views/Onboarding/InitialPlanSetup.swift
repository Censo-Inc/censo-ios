//
//  ImplicitOwnerPlanSetup.swift
//  Vault
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
        VStack {
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
                }
            } else {
                Spacer(minLength: 20)
                Image("LargeFaceScan")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 298)
                    .saturation(0.0)
                Spacer()
                VStack(alignment: .leading) {
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Step 1")
                            .font(.system(size: 18))
                            .padding(.bottom, 1)
                            .bold()
                        Text("Scan your face")
                            .font(.system(size: 24))
                            .bold()
                    }
                    .padding()
                    
                    VStack(alignment: .leading) {
                        Text("Access to your seed phrases is always sealed behind a live scan of your face")
                            .font(.system(size: 14))
                            .padding(.bottom, 1)
                        
                        Text("Capture a 3D map of your face and confirm your live, physical presence with third-party-verified technology")
                            .font(.system(size: 14))
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
                                .font(.system(size: 24, weight: .semibold))
                            Spacer()
                        }
                    }
                    .buttonStyle(RoundedButtonStyle())
                    .padding()
                    .frame(maxWidth: .infinity)
                    
                    HStack {
                        Image(systemName: "info.circle")
                        Text("Learn more")
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
        }
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
            let guardianPublicKey = try session.getOrCreateApproverKey(participantId: participantId).publicExternalRepresentation()
            let policySetupHelper = try PolicySetupHelper(
                threshold: 1,
                guardians: [(
                    participantId,
                    guardianPublicKey
                )]
            )
            createPolicyParams = CreatePolicyParams(
                guardianPublicKey: guardianPublicKey,
                intermediatePublicKey: policySetupHelper.intermediatePublicKey,
                masterEncryptionPublicKey: policySetupHelper.masterEncryptionPublicKey,
                encryptedMasterPrivateKey: policySetupHelper.encryptedMasterPrivateKey,
                encryptedShard: policySetupHelper.guardians[0].encryptedShard
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
