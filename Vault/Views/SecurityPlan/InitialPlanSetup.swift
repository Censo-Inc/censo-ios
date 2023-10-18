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

    @State private var showingBiometry = false
    @State private var guardianPublicKey: Base58EncodedPublicKey?
    @State private var policySetupHelper: PolicySetupHelper?

    var body: some View {
        VStack {
            if showingBiometry {
                FacetecAuth<API.CreatePolicyApiResponse>(session: session) { verificationId, facetecBiometry in
                        .createPolicy(
                            API.CreatePolicyApiRequest(
                                intermediatePublicKey: policySetupHelper!.intermediatePublicKey,
                                encryptedMasterPrivateKey: policySetupHelper!.encryptedMasterPrivateKey,
                                masterEncryptionPublicKey: policySetupHelper!.masterEncryptionPublicKey,
                                participantId: participantId,
                                encryptedShard: policySetupHelper!.guardians[0].encryptedShard,
                                guardianPublicKey: guardianPublicKey!,
                                biometryVerificationId: verificationId,
                                biometryData: facetecBiometry
                            )
                        )
                } onSuccess: { response in
                    showingBiometry = false
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
                            //.padding(.bottom, 1)
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
                        showingBiometry = true
                    } label: {
                        HStack {
                            Spacer()
                            Image("FaceScanBW")
                                .resizable()
                                .frame(width: 36, height: 36)
                            Text("Begin face scan")
                            Spacer()
                        }
                    }
                    .buttonStyle(RoundedButtonStyle())
                    .padding()
                    .frame(maxWidth: .infinity)
                    .disabled(guardianPublicKey == nil)
                    
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
                showingBiometry = false
            } label: {
                Text("OK")
            }
        } message: { error in
            Text("There was an error submitting your info.\n\(error.localizedDescription)")
        }
        .onAppear {
            do {
                guardianPublicKey = try session.approverKey(participantId: participantId).publicExternalRepresentation()
                policySetupHelper = try PolicySetupHelper(
                    threshold: 1,
                    guardians: [(
                        participantId,
                        guardianPublicKey!
                    )]
                )
            } catch {
                showError(error)
            }
        }
    }
    
    private func showError(_ error: Error) {
        self.error = error
        self.showingError = true
    }
}

#Preview {
    NavigationView {
        InitialPlanSetup(session: .sample, onComplete: {_ in})
    }
}
