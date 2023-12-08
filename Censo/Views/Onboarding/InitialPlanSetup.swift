//
//  ImplicitOwnerPlanSetup.swift
//  Censo
//
//  Created by Brendan Flood on 10/10/23.
//

import SwiftUI
import Moya

struct InitialPlanSetup: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss
    
    var session: Session
    var onComplete: (API.OwnerState) -> Void
    
    @State private var showingError = false
    @State private var error: Error?
    @State private var needBiometricConsent = true

    struct CreatePolicyParams {
        var approverPublicKey: Base58EncodedPublicKey
        var intermediatePublicKey: Base58EncodedPublicKey
        var masterEncryptionPublicKey: Base58EncodedPublicKey
        var encryptedMasterPrivateKey: Base64EncodedString
        var encryptedShard: Base64EncodedString
        var participantId: ParticipantId
    }
    
    @State private var createPolicyParams: CreatePolicyParams?
    @State private var usePasswordAuth = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let createPolicyParams {
                if (usePasswordAuth) {
                    CreatePassword { cryptedPassword in
                        apiProvider.decodableRequest(
                            with: session,
                            endpoint: .createPolicyWithPassword(
                                API.CreatePolicyWithPasswordApiRequest(
                                    intermediatePublicKey: createPolicyParams.intermediatePublicKey,
                                    encryptedMasterPrivateKey: createPolicyParams.encryptedMasterPrivateKey,
                                    masterEncryptionPublicKey: createPolicyParams.masterEncryptionPublicKey,
                                    participantId: createPolicyParams.participantId,
                                    encryptedShard: createPolicyParams.encryptedShard,
                                    approverPublicKey: createPolicyParams.approverPublicKey,
                                    password: API.Password(cryptedPassword: cryptedPassword)
                                )
                            )
                        ) { (result: Result<API.CreatePolicyWithPasswordApiResponse, MoyaError>) in
                            switch result {
                            case .failure:
                                dismiss()
                            case .success(let response):
                                onComplete(response.ownerState)
                            }
                        }
                    }
                } else {
                    FacetecAuth<API.CreatePolicyApiResponse>(session: session) { verificationId, facetecBiometry in
                            .createPolicy(
                                API.CreatePolicyApiRequest(
                                    intermediatePublicKey: createPolicyParams.intermediatePublicKey,
                                    encryptedMasterPrivateKey: createPolicyParams.encryptedMasterPrivateKey,
                                    masterEncryptionPublicKey: createPolicyParams.masterEncryptionPublicKey,
                                    participantId: createPolicyParams.participantId,
                                    encryptedShard: createPolicyParams.encryptedShard,
                                    approverPublicKey: createPolicyParams.approverPublicKey,
                                    biometryVerificationId: verificationId,
                                    biometryData: facetecBiometry
                                )
                            )
                    } onSuccess: { response in
                        onComplete(response.ownerState)
                    } onCancelled: {
                        dismiss()
                    }
                }
            } else {
                ScrollView {
                    Spacer()
                    Image("LargeFaceScan")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 298, maxHeight: 200)
                        .saturation(0.0)
                    
                    VStack(alignment: .leading) {
                        Spacer()
                        
                        Text("Scan your face (optional)")
                            .font(.title2)
                            .bold()
                            .padding([.horizontal])
                        
                        VStack(alignment: .leading) {
                            Text("A face scan will ensure that only you have access to your seed phrase.")
                                .font(.subheadline)
                                .padding(.bottom, 4)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("If you opt in, you can capture and store an anonymous 3D map of your face to confirm your live physical presence.")
                                .font(.subheadline)
                                .padding(.bottom, 1)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        
                        Text("By tapping Begin face scan, I consent to the collection and processing of a scan of my face for the purposes of authentication in connection with my use of the Censo App.")
                            .font(.caption)
                            .italic()
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding([.horizontal])
                        
                        Text(try! AttributedString(markdown: "[To use the Censo App without biometric authentication, tap here to use a password instead.](#)"))
                            .font(.caption)
                            .italic()
                            .tint(.black)
                            .multilineTextAlignment(.leading)
                            .padding([.top, .horizontal])
                            .fixedSize(horizontal: false, vertical: true)
                            .environment(\.openURL, OpenURLAction { url in
                                usePasswordAuth = true
                                startPolicyCreation()
                                return .handled
                            })
                        
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
            let participantId: ParticipantId = .random()
            let ownerApproverPublicKey = try session.getOrCreateApproverKey(participantId: participantId).publicExternalRepresentation()
            let intermediateEncryptionKey = try EncryptionKey.generateRandomKey()
            let masterEncryptionKey = try EncryptionKey.generateRandomKey()
            
            createPolicyParams = CreatePolicyParams(
                approverPublicKey: ownerApproverPublicKey,
                intermediatePublicKey: try intermediateEncryptionKey.publicExternalRepresentation(),
                masterEncryptionPublicKey: try masterEncryptionKey.publicExternalRepresentation(),
                encryptedMasterPrivateKey: try intermediateEncryptionKey.encrypt(data: masterEncryptionKey.privateKeyRaw()),
                encryptedShard: try intermediateEncryptionKey.shard(
                    threshold: 1,
                    participants: [(participantId, ownerApproverPublicKey)]
                ).first(where: { $0.participantId == participantId })!.encryptedShard,
                participantId: participantId
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
