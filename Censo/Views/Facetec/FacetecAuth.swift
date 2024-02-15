//
//  FacetecSetup.swift
//  Censo
//
//

import SwiftUI
import Moya
import FaceTecSDK

struct FacetecAuth<ResponseType: BiometryVerificationResponse>: View {
    @EnvironmentObject var ownerRepository: OwnerRepository

    @State private var step: Step = .idle

    enum Step {
        case idle
        case loading
        case ready(API.InitBiometryVerificationApiResponse)
        case failure(Error)
    }

    var onFaceScanReady: FaceScanReadyCallback<ResponseType>
    var onSuccess: (ResponseType) -> Void
    var onCancelled: () -> Void

    var body: some View {
        Group {
            switch step {
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
                    onFaceScanReady(
                        API.Authentication.FacetecBiometry(
                            verificationId: initBiometryResponse.id,
                            faceScan: "",
                            auditTrailImage: "",
                            lowQualityAuditTrailImage: ""
                        )
                    ) { (result: Result<ResponseType, MoyaError>) in
                        switch result {
                        case .success(let response):
                            onSuccess(response)
                        case .failure(let error):
                            step = .failure(error)
                        }
                    }
                }
#else
                ProgressView()
                    .sheet(isPresented: .constant(true)) {
                        NavigationView {
                            FacetecUIKitWrapper(
                                verificationId: initBiometryResponse.id,
                                sessionToken: initBiometryResponse.sessionToken,
                                onBack: {
                                    onCancelled()
                                },
                                onError: { error in
                                    step = .failure(error)
                                },
                                onFaceScanReady: onFaceScanReady,
                                onSuccess: onSuccess
                            )
                            .interactiveDismissDisabled()
                        }
                    }
#endif
            case .failure(let error):
                Group {
                    switch (error) {
                    case is FaceTecSessionError:
                        RetryView(error: FacetecError(status: (error as! FaceTecSessionError).status), action: prepareBiometryVerification)
                    default:
                        RetryView(error: error, action: prepareBiometryVerification)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        DismissButton(icon: .back, action: onCancelled)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }

    private func prepareBiometryVerification() {
        step = .loading

        ownerRepository.initBiometryVerification { result in
            switch result {
            case .success(let response):
#if INTEGRATION
                step = .ready(response)
#else
                FaceTec.sdk.initialize(
                    deviceKeyId: response.deviceKeyId,
                    productionKeyText: response.productionKeyText,
                    faceScanEncryptionKey: response.biometryEncryptionPublicKey
                ) { success in
                    if success {
                        step = .ready(response)
                    } else {
                        step = .failure(FacetecError("Facetec failed with status \(FaceTec.sdk.getStatus().rawValue)"))
                    }
                }
#endif
            case .failure(let error):
                step = .failure(error)
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
         
        customization.frameCustomization.borderColor = UIColor.Censo.primaryForeground
        
        customization.overlayCustomization.showBrandingImage = false
        
        let solidBlackGradient = CAGradientLayer()
        solidBlackGradient.colors = [UIColor.Censo.darkBlue.cgColor, UIColor.Censo.darkBlue.cgColor]
        solidBlackGradient.startPoint = CGPoint(x: 0.0, y: 0.0)
        solidBlackGradient.endPoint = CGPoint(x: 1, y: 0)
        solidBlackGradient.cornerRadius = 20
        customization.feedbackCustomization.backgroundColor = solidBlackGradient
        customization.feedbackCustomization.textColor = UIColor.Censo.aquaBlue
        
        customization.guidanceCustomization.buttonBackgroundNormalColor = UIColor.Censo.darkBlue
        customization.guidanceCustomization.buttonTextNormalColor = UIColor.Censo.buttonTextColor
        customization.guidanceCustomization.buttonTextHighlightColor = UIColor.Censo.buttonTextColor
        customization.guidanceCustomization.buttonTextDisabledColor = UIColor.darkGray
        customization.guidanceCustomization.foregroundColor = UIColor.Censo.primaryForeground
        customization.guidanceCustomization.retryScreenImageBorderColor = UIColor.Censo.primaryForeground
        customization.guidanceCustomization.cameraPermissionsScreenImage = UIImage(named: "Camera")?.resized(to: CGSize(width: 80, height: 60))
        
        customization.ovalCustomization.strokeColor = UIColor.Censo.darkBlue
        customization.ovalCustomization.progressColor1 = UIColor.Censo.darkBlue
        customization.ovalCustomization.progressColor2 = UIColor.Censo.aquaBlue
        
        customization.resultScreenCustomization.foregroundColor = UIColor.Censo.darkBlue
        customization.resultScreenCustomization.uploadProgressFillColor = UIColor.Censo.darkBlue
        customization.resultScreenCustomization.uploadProgressTrackColor = UIColor.darkGray
        customization.resultScreenCustomization.activityIndicatorColor = UIColor.Censo.darkBlue
        customization.resultScreenCustomization.resultAnimationBackgroundColor = UIColor.Censo.buttonBackgroundColor
        customization.resultScreenCustomization.resultAnimationForegroundColor = UIColor.Censo.buttonTextColor
        
        customization.cancelButtonCustomization.customImage = UIImage(
            systemName: "xmark"
        )?.resized(
            to: CGSize(width: 20, height: 20)
        ).withTintColor(
            UIColor.Censo.primaryForeground
        )
        customization.cancelButtonCustomization.location = .custom
        customization.cancelButtonCustomization.customLocation = CGRect(x: 12, y: 12, width: 20, height: 20)
        customization.frameCustomization.borderWidth = 0
        customization.frameCustomization.cornerRadius = 0
        
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
        FacetecAuth<API.UnlockApiResponse>(onFaceScanReady: {_, _ in }, onSuccess: { _ in }, onCancelled: {})  
    }
}

#endif
