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
        var entropy: Base64EncodedString
    }
    
    @State private var createPolicyParams: CreatePolicyParams?
    @State private var usePasswordAuth = false
    @State private var showLearnMore = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let createPolicyParams {
                if (usePasswordAuth) {
                    NavigationStack {
                        CreatePassword { cryptedPassword in
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
                                case .failure:
                                    dismiss()
                                case .success(let response):
                                    ownerStateStoreController.replace(response.ownerState)
                                }
                            }
                        }
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationTitle("Create a password")
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationBarBackButtonHidden(true)
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
                    FacetecAuth<API.CreatePolicyApiResponse>(
                        onFaceScanReady: { facetecBiometry, completion in
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
                        },
                        onSuccess: { response in
                            ownerStateStoreController.replace(response.ownerState)
                        },
                        onCancelled: {
                            self.createPolicyParams = nil
                            dismiss()
                        }
                    )
                }
            } else {
                GeometryReader { geometry in
                    ZStack(alignment: .bottom) {
                        Spacer()
                            .frame(maxHeight: geometry.size.height * 0.05)
                        VStack {
                            Image("FaceScanHandWithPhone")
                                .resizable()
                                .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height * 0.9)
                            Spacer()
                        }
                        .padding(.leading, geometry.size.width * 0.1)
                        .padding(.top, 10)
                        
                        VStack(spacing: 0) {
                            Spacer()
                            
                            VStack(alignment: .leading) {
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
                                    .accessibilityIdentifier("usePasswordLink")

                                BeginFaceScanButton {
                                    startPolicyCreation()
                                }

                                Button {
                                    showLearnMore = true
                                } label: {
                                    HStack {
                                        Image(systemName: "info.circle")
                                        Text("Learn more")
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.horizontal)
                            .padding(.horizontal)
                        }
                    }
                    .onboardingCancelNavBar(navigationTitle: "Anonymously scan your face", onCancel: onCancel, showAsBack: true)
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
        .sheet(isPresented: $showLearnMore) {
            LearnMore(title: "Face Scan & Privacy", showLearnMore: $showLearnMore) {
                VStack {
                    Text("""
                        Censo uses a face scan to ensure your security and protect your privacy.  Any security actions you take with Censo require a face scan as one of the sources of authentication.
                        
                        Censo utilizes face technology built by facetec.com. Facetec’s certified liveness plus 3D face matching ensures that you and only you can access your seed phrases and make changes to your security.  Facetec provides over 2 billion 3D liveness checks annually.
                        
                        By utilizing Facetec rather than the biometrics on your mobile device, we can assure that you’ll never lose access to your seed phrases, even in the event you lose your mobile device or change the biometry on your phone.
                        
                        Censo maintains only an encrypted version of your face scan that can never be used to identify you or tied to your identity, although it does allow Censo to positively identify you as a user.
                        """
                    )
                    .padding()
                    
                }
            }
        }
    }
    
    private func showError(_ error: Error) {
        self.error = error
        self.showingError = true
    }
    
    private func startPolicyCreation() {
        do {
            let participantId: ParticipantId = .random()
            let ownerApproverKey = try ownerRepository.getOrCreateApproverKey(participantId: participantId, entropy: ownerState.entropy.data)
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
