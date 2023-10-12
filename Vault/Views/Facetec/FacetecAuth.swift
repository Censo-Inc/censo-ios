//
//  FacetecSetup.swift
//  Vault
//
//

import SwiftUI
import Moya
import FaceTecSDK
import raygun4apple

struct FacetecAuth<ResponseType: BiometryVerificationResponse>: View {
    @Environment(\.apiProvider) var apiProvider

    @State private var setupStep: SetupStep = .idle

    enum SetupStep {
        case idle
        case loading
        case ready(API.InitBiometryVerificationApiResponse)
        case failure(Error)
    }

    var session: Session
    var onReadyToUploadResults: ResultsReadyCallback
    var onSuccess: (ResponseType) -> Void

    var body: some View {
        Group {
            switch setupStep {
            case .idle:
                ProgressView()
                    .onAppear(perform: prepareBiometryVerification)
            case .loading:
                ProgressView()
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
                    ) { (result: Result<ResponseType, MoyaError>) in
                        switch result {
                        case .success(let response):
                            onSuccess(response)
                        case .failure(let error):
                            setupStep = .failure(error)
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
                    onError: { error in
                        setupStep = .failure(error)
                    },
                    onReadyToUploadResults: onReadyToUploadResults,
                    onSuccess: onSuccess
                )
#endif
            case .failure(let error):
                RetryView(error: error, action: prepareBiometryVerification)
            }
        }
    }

    private func prepareBiometryVerification() {
        setupStep = .loading

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
                        let error = FacetecError(rawStatus: FaceTec.sdk.getStatus().rawValue)
                        RaygunClient.sharedInstance().send(error: error, tags: ["FaceTec"], customData: nil)
                        setupStep = .failure(error)
                    }
                }
            case .failure(let error):
                setupStep = .failure(error)
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
        customizations()
    }
    
    func customizations() {
        let customization = FaceTecCustomization()
         
        customization.cancelButtonCustomization.location = FaceTecCancelButtonLocation.disabled
        
        customization.frameCustomization.borderColor = UIColor.black
        
        customization.overlayCustomization.showBrandingImage = false
        
        let solidBlackGradient = CAGradientLayer()
        solidBlackGradient.colors = [UIColor.black.cgColor, UIColor.black.cgColor]
        solidBlackGradient.startPoint = CGPoint(x: 0.0, y: 0.0)
        solidBlackGradient.endPoint = CGPoint(x: 1, y: 0)
        solidBlackGradient.cornerRadius = 20
        customization.feedbackCustomization.backgroundColor = solidBlackGradient
        customization.feedbackCustomization.textColor = UIColor.white
        
        customization.guidanceCustomization.buttonBackgroundNormalColor = UIColor.black
        customization.guidanceCustomization.buttonTextDisabledColor = UIColor.darkGray
        customization.guidanceCustomization.foregroundColor = UIColor.black
        customization.guidanceCustomization.retryScreenImageBorderColor = UIColor.black
        customization.guidanceCustomization.cameraPermissionsScreenImage = UIImage(named: "Camera")?.resized(to: CGSize(width: 80, height: 60))
        
        customization.ovalCustomization.strokeColor = UIColor.black
        customization.ovalCustomization.progressColor1 = UIColor.black
        customization.ovalCustomization.progressColor2 = UIColor.black
        
        customization.resultScreenCustomization.foregroundColor = UIColor.black
        customization.resultScreenCustomization.uploadProgressFillColor = UIColor.black
        customization.resultScreenCustomization.uploadProgressTrackColor = UIColor.darkGray
        customization.resultScreenCustomization.activityIndicatorColor = UIColor.black
        customization.resultScreenCustomization.resultAnimationBackgroundColor = UIColor.black
        customization.resultScreenCustomization.resultAnimationForegroundColor = UIColor.white
        
        // Apply Customization
        FaceTec.sdk.setCustomization(customization);
    }
}

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

#if DEBUG
struct FacetecAuth_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            FacetecAuth<API.UnlockApiResponse>(session: .sample, onReadyToUploadResults: {_,_ in .user}) { _ in }
        }
    }
}

#endif
