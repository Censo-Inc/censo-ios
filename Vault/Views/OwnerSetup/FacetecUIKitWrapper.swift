//
//  FacetecUIKitWrapper.swift
//  Vault
//
//

import SwiftUI
import Moya
import FaceTecSDK

struct FacetecUIKitWrapper: UIViewControllerRepresentable {
    @Environment(\.apiProvider) var apiProvider

    var session: Session
    var verificationId: String
    var sessionToken: String
    var onBack: () -> Void
    var onSuccess: () -> Void
    var onError: (Error) -> Void

    typealias UIViewControllerType = UIViewController

    func makeUIViewController(context: Context) -> UIViewController {
        let sdkViewController = FaceTec.sdk.createSessionVC(faceScanProcessorDelegate: context.coordinator, sessionToken: sessionToken)
        return sdkViewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Update the UIKit view controller if needed
    }

    typealias Coordinator = FacetecUIKitWrapperCoordinator

    func makeCoordinator() -> Coordinator {
        FacetecUIKitWrapperCoordinator(session: session, apiProvider: apiProvider, verificationId: verificationId, onSuccess: onSuccess, onBack: onBack, onError: onError)
    }
}

struct FaceTecSessionError: Error {
    var status: FaceTecSessionStatus
}

class FacetecUIKitWrapperCoordinator: NSObject, FaceTecFaceScanProcessorDelegate {
    var session: Session
    var apiProvider: MoyaProvider<API>
    var verificationId: String
    var onSuccess: () -> Void
    var onBack: () -> Void
    var onError: (Error) -> Void

    init(session: Session, apiProvider: MoyaProvider<API>, verificationId: String, onSuccess: @escaping () -> Void, onBack: @escaping () -> Void, onError: @escaping (Error) -> Void) {
        self.session = session
        self.apiProvider = apiProvider
        self.verificationId = verificationId
        self.onSuccess = onSuccess
        self.onBack = onBack
        self.onError = onError
    }

    func processSessionWhileFaceTecSDKWaits(sessionResult: FaceTecSessionResult, faceScanResultCallback: FaceTecFaceScanResultCallback) {
        // Handles early exit scenarios where there is no FaceScan to handle -- i.e. User Cancellation, Timeouts, etc.
        switch (sessionResult.status) {
        case FaceTecSessionStatus.userCancelled:
            //faceScanResultCallback.onFaceScanResultCancel() // FIXME this closes complete pop-up. Try later embedded mode.
            onBack()
        case FaceTecSessionStatus.sessionCompletedSuccessfully:
            uploadResultsToServer(sessionResult: sessionResult, faceScanResultCallback: faceScanResultCallback)
        default:
            //faceScanResultCallback.onFaceScanResultCancel() // FIXME this closes complete pop-up. Try later embedded mode.
            onError(FaceTecSessionError(status: sessionResult.status))
        }
    }

    private func uploadResultsToServer(sessionResult: FaceTecSessionResult, faceScanResultCallback: FaceTecFaceScanResultCallback) { // Send facescan to server
        apiProvider.decodableRequest(
            with: session,
            endpoint: .confirmBiometryVerification(
                verificationId: verificationId,
                faceScan: sessionResult.faceScanBase64 ?? "",
                auditTrailImage: sessionResult.auditTrailCompressedBase64?.first ?? "",
                lowQualityAuditTrailImage: sessionResult.lowQualityAuditTrailCompressedBase64?.first ?? ""
            )
        ) { [weak self] (result: Result<API.ConfirmBiometryVerificationApiResponse, MoyaError>) in
            switch result {
            case .success(let response):
                FaceTecCustomization.setOverrideResultScreenSuccessMessage("Authenticated")

                // In v9.2.0+, simply pass in scanResultBlob to the proceedToNextStep function to advance the User flow.
                // scanResultBlob is a proprietary, encrypted blob that controls the logic for what happens next for the User.
                faceScanResultCallback.onFaceScanGoToNextStep(scanResultBlob: response.scanResultBlob)
            case .failure(let error):
                self?.onError(error)

                faceScanResultCallback.onFaceScanResultCancel()
            }
        }
    }

    /**
     This method will be called exactly once after the Session has completed and when using the Session constructor with a FaceTecFaceScanProcessor.
     */
    func onFaceTecSDKCompletelyDone() {
        onSuccess()
    }
}
