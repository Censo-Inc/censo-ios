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

struct FacetecSetup: View {
    @Environment(\.apiProvider) var apiProvider

    @State private var setupStep: SetupStep = .idle

    enum SetupStep {
        case idle
        case loading
        case ready(API.InitiBiometryVerificationApiResponse)
        case error(Error)
    }

    var contact: API.Contact
    var onSuccess: () -> Void

    var body: some View {
        switch setupStep {
        case .idle:
            ProgressView {
                Text("Preparing liveness detection")
            }
            .onAppear(perform: prepareBiometryVerification)
        case .loading:
            ProgressView {
                Text("Preparing liveness detection")
            }
        case .ready(let initBiometryResponse):
            #if INTEGRATION
            ProgressView {
                Text("Skipping biometry...")
            }
            .onAppear {
                apiProvider.request(
                    .confirmBiometryVerification(
                        verificationId: initBiometryResponse.id,
                        faceScan: contact.identifier,
                        auditTrailImage: contact.identifier,
                        lowQualityAuditTrailImage: contact.identifier
                    )
                ) { result in
                    switch result {
                    case .success(let response) where response.statusCode < 400:
                        onSuccess()
                    case .success(let response):
                        setupStep = .error(MoyaError.statusCode(response))
                    case .failure(let error):
                        setupStep = .error(error)
                    }
                }
            }
            #else
            FacetecUIKitWrapper(
                verificationId: initBiometryResponse.id,
                sessionToken: initBiometryResponse.sessionToken,
                onBack: {
                    setupStep = .ready(initBiometryResponse)
                },
                onSuccess: onSuccess,
                onError: { error in
                    setupStep = .error(error)
                }
            )
            #endif
        case .error(let error):
            RetryView(error: error, action: { setupStep = .loading })
        }
    }

    private func prepareBiometryVerification() {
        apiProvider.decodableRequest(.initBiometryVerification) { (result: Result<API.InitiBiometryVerificationApiResponse, MoyaError>) in
            switch result {
            case .success(let response):
                FaceTec.sdk.initialize(
                    deviceKeyId: response.deviceKeyId,
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
    func initialize(deviceKeyId: String, faceScanEncryptionKey: String, completion: @escaping (Bool) -> Void) {
#if PRODUCTION
        FaceTec.sdk.initializeInProductionMode(
            productionKeyText: "SOMEKEYTEXT",
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
struct FacetecSetup_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            FacetecSetup(contact: .sample, onSuccess: {})
        }
    }
}

extension API.Contact {
    static var sample: Self {
        API.Contact(identifier: "", contactType: .email, value: "something@test.com", verified: true)
    }
}
#endif
