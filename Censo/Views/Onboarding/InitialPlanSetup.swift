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
        var approverPublicKeySignatureByIntermediateKey: Base64EncodedString
        var intermediatePublicKey: Base58EncodedPublicKey
        var masterEncryptionPublicKey: Base58EncodedPublicKey
        var encryptedMasterPrivateKey: Base64EncodedString
        var encryptedShard: Base64EncodedString
        var participantId: ParticipantId
        var masterKeySignature: Base64EncodedString
    }
    
    @State private var createPolicyParams: CreatePolicyParams?
    @State private var usePasswordAuth = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let createPolicyParams {
                if (usePasswordAuth) {
                    NavigationStack {
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
                                        approverPublicKeySignatureByIntermediateKey: createPolicyParams.approverPublicKeySignatureByIntermediateKey,
                                        password: API.Password(cryptedPassword: cryptedPassword),
                                        masterKeySignature: createPolicyParams.masterKeySignature
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
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar(content: {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button {
                                    self.createPolicyParams = nil
                                    self.usePasswordAuth = false
                                } label: {
                                    Image(systemName: "chevron.left")
                                }
                            }
                        })
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
                                    approverPublicKeySignatureByIntermediateKey: createPolicyParams.approverPublicKeySignatureByIntermediateKey,
                                    biometryVerificationId: verificationId,
                                    biometryData: facetecBiometry,
                                    masterKeySignature: createPolicyParams.masterKeySignature
                                )
                            )
                    } onSuccess: { response in
                        onComplete(response.ownerState)
                    } onCancelled: {
                        dismiss()
                    }
                }
            } else {
                GeometryReader { geometry in
                    ZStack(alignment: .bottom) {
                        VStack {
                            Image("FaceScanHandWithPhone")
                                .resizable()
                                .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height * 0.9)
                            Spacer()
                        }
                        .padding(.leading, geometry.size.width * 0.1)
                        
                        VStack(spacing: 0) {
                            Spacer()
                            
                            VStack(alignment: .leading) {
                                Text("Anonymously scan your face")
                                    .fixedSize(horizontal: false, vertical: true)
                                    .font(.title2)
                                    .bold()
                                
                                Text(try! AttributedString(markdown: "[To use the Censo App without biometric authentication, tap here to use a password instead.](#)"))
                                    .font(.subheadline)
                                    .tint(Color.Censo.primaryForeground)
                                    .multilineTextAlignment(.leading)
                                    .padding([.top])
                                    .fixedSize(horizontal: false, vertical: true)
                                    .environment(\.openURL, OpenURLAction { url in
                                        usePasswordAuth = true
                                        startPolicyCreation()
                                        return .handled
                                    })
                                    .padding(.bottom)
                                
                                Text("By tapping Begin face scan, I consent to the collection and processing of a scan of my face for the purposes of authentication in connection with my use of the Censo App.")
                                    .font(.caption)
                                    .italic()
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.bottom)
                                
                                Button {
                                    startPolicyCreation()
                                } label: {
                                    HStack {
                                        Spacer()
                                        Image("FaceScanBW")
                                            .renderingMode(.template)
                                            .resizable()
                                            .frame(width: 36, height: 36)
                                        Text("Begin face scan")
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                        Spacer()
                                    }
                                }
                                .buttonStyle(RoundedButtonStyle())
                                .padding(.bottom)
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.horizontal)
                            .padding(.horizontal)
                        }
                    }
                }
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
            let ownerApproverKey = try session.getOrCreateApproverKey(participantId: participantId)
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
                ).first(where: { $0.participantId == participantId })!.encryptedShard,
                participantId: participantId,
                masterKeySignature: try ownerApproverKey.signature(for: masterPublicKey.data)
            )
        } catch {
            showError(error)
        }
    }
}

#if DEBUG
#Preview {
    InitialPlanSetup(session: .sample, onComplete: {_ in})
        .foregroundColor(.Censo.primaryForeground)
}
#endif
