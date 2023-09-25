//
//  FacetecSetup.swift
//  Vault
//
//

import SwiftUI
import Moya
import FaceTecSDK
import raygun4apple

struct FacetecError: Error, Sendable {
    var status: FaceTecSDKStatus
}

struct FacetecAuth: View {
    @Environment(\.apiProvider) var apiProvider

    @State private var setupStep: SetupStep = .idle

    enum SetupStep {
        case idle
        case ready(API.InitBiometryVerificationApiResponse)
        case error(Error)
    }

    var session: Session
    var onSuccess: (API.OwnerState) -> Void
    var onReadyToUploadResults: ResultsReadyCallback

    var body: some View {
        switch setupStep {
        case .idle:
            ProgressView {
                Text("Preparing liveness detection")
            }
            .onAppear(perform: prepareBiometryVerification)
        case .ready(let initBiometryResponse):
            #if INTEGRATION
            ProgressView {
                Text("Skipping biometry...")
            }
            .onAppear {
                apiProvider.decodableRequest(
                    with: session,
                    endpoint: onReadyToUploadResults(
                        initBiometryResponse.id,
                        API.FacetecBiometry(
                            faceScan: session.userCredentials.userIdentifier.data(using: .utf8)!.base64EncodedString(),
                            auditTrailImage: session.userCredentials.userIdentifier.data(using: .utf8)!.base64EncodedString(),
                            lowQualityAuditTrailImage: session.userCredentials.userIdentifier.data(using: .utf8)!.base64EncodedString()
                        )
                    )
                ) { (result: Result<API.OwnerStateResponse, MoyaError>) in
                    switch result {
                    case .success(let response):
                        onSuccess(response.ownerState)
                    case .failure(let error):
                        setupStep = .error(error)
                    }
                }
            }
            #else
            FacetecUIKitWrapper(
                session: session,
                verificationId: initBiometryResponse.id,
                sessionToken: initBiometryResponse.sessionToken,
                onBack: {
                    setupStep = .ready(initBiometryResponse)
                },
                onSuccess: onSuccess,
                onError: { error in
                    setupStep = .error(error)
                },
                onReadyToUploadResults: onReadyToUploadResults
            )
            #endif
        case .error(let error):
            RetryView(error: error, action: { setupStep = .idle })
        }
    }

    private func prepareBiometryVerification() {
        apiProvider.decodableRequest(with: session, endpoint: .initBiometryVerification) { (result: Result<API.InitBiometryVerificationApiResponse, MoyaError>) in
            switch result {
            case .success(let response):
                FaceTec.sdk.initialize(
                    deviceKeyId: response.deviceKeyId,
                    productionKeyText: response.productionKeyText,
                    faceScanEncryptionKey: response.biometryEncryptionPublicKey
                ) { success in
                    if success {
                        setupStep = .ready(response)
                    } else {
                        let error = FacetecError(status: FaceTec.sdk.getStatus())
                        RaygunClient.sharedInstance().send(error: error, tags: ["FaceTec"], customData: nil)
                        setupStep = .error(error)
                    }
                }
            case .failure(let error):
                setupStep = .error(error)
            }
        }
    }
}

extension FaceTecSDKProtocol {
    func initialize(deviceKeyId: String, productionKeyText: String, faceScanEncryptionKey: String, completion: @escaping (Bool) -> Void) {
#if PRODUCTION
        FaceTec.sdk.initializeInProductionMode(
            productionKeyText: productionKeyText,
            deviceKeyIdentifier: deviceKeyId, faceScanEncryptionKey:
            faceScanEncryptionKey,
            completion: completion
        )
#else
        FaceTec.sdk.initializeInDevelopmentMode(
            deviceKeyIdentifier: deviceKeyId,
            faceScanEncryptionKey: faceScanEncryptionKey,
            completion: completion
        )
#endif
    }
}

#if DEBUG
struct FacetecAuth_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            FacetecAuth(session: .sample, onSuccess: {_ in }, onReadyToUploadResults: {_,_ in .user})
        }
    }
}

#endif
