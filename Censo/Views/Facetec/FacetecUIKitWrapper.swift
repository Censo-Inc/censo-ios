//
//  FacetecUIKitWrapper.swift
//  Censo
//
//

import SwiftUI
import Moya
import FaceTecSDK

typealias ResultsReadyCallback = (String, API.FacetecBiometry) -> API.Endpoint

protocol BiometryVerificationResponse : Decodable {
    var scanResultBlob: String {get set}
}

struct FacetecUIKitWrapper<ResponseType: BiometryVerificationResponse>: UIViewControllerRepresentable {
    @Environment(\.apiProvider) var apiProvider

    var session: Session
    var verificationId: String
    var sessionToken: String
    var onBack: () -> Void
    var onError: (Error) -> Void
    var onReadyToUploadResults: ResultsReadyCallback
    var onSuccess: (ResponseType) -> Void

    typealias UIViewControllerType = UIViewController

    func makeUIViewController(context: Context) -> UIViewController {
        let sdkViewController = FaceTec.sdk.createSessionVC(faceScanProcessorDelegate: context.coordinator, sessionToken: sessionToken)
        return sdkViewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Update the UIKit view controller if needed
    }

    typealias Coordinator = FacetecUIKitWrapperCoordinator<ResponseType>

    func makeCoordinator() -> Coordinator {
        FacetecUIKitWrapperCoordinator(
            session: session,
            apiProvider: apiProvider,
            verificationId: verificationId,
            onBack: onBack,
            onError: onError,
            onReadyToUploadResults: onReadyToUploadResults,
            onSuccess: onSuccess
        )
    }
}

struct FaceTecSessionError: Error {
    var status: FaceTecSessionStatus
}

class FacetecUIKitWrapperCoordinator<ResponseType: BiometryVerificationResponse>: NSObject, FaceTecFaceScanProcessorDelegate {
    var session: Session
    var apiProvider: MoyaProvider<API>
    var verificationId: String
    var onBack: () -> Void
    var onError: (Error) -> Void
    var onReadyToUploadResults: ResultsReadyCallback
    var onSuccess: (ResponseType) -> Void
    var response: ResponseType? = nil

    init(session: Session, apiProvider: MoyaProvider<API>, verificationId: String, onBack: @escaping () -> Void, onError: @escaping (Error) -> Void, onReadyToUploadResults: @escaping ResultsReadyCallback, onSuccess: @escaping (ResponseType) -> Void) {
        self.session = session
        self.apiProvider = apiProvider
        self.verificationId = verificationId
        self.onBack = onBack
        self.onError = onError
        self.onReadyToUploadResults = onReadyToUploadResults
        self.onSuccess = onSuccess
    }

    func processSessionWhileFaceTecSDKWaits(sessionResult: FaceTecSessionResult, faceScanResultCallback: FaceTecFaceScanResultCallback) {
        // Handles early exit scenarios where there is no FaceScan to handle -- i.e. User Cancellation, Timeouts, etc.
        switch (sessionResult.status) {
        case FaceTecSessionStatus.userCancelled:
            faceScanResultCallback.onFaceScanResultCancel()
            onBack()
        case FaceTecSessionStatus.sessionCompletedSuccessfully:
            uploadResultsToServer(sessionResult: sessionResult, faceScanResultCallback: faceScanResultCallback)
        default:
            faceScanResultCallback.onFaceScanResultCancel()
            onError(FaceTecSessionError(status: sessionResult.status))
        }
    }

    private func uploadResultsToServer(sessionResult: FaceTecSessionResult, faceScanResultCallback: FaceTecFaceScanResultCallback) { // Send facescan to server
        apiProvider.decodableRequest(
            with: session,
            endpoint: onReadyToUploadResults(
                verificationId,
                API.FacetecBiometry(
                    faceScan: sessionResult.faceScanBase64 ?? "",
                    auditTrailImage: sessionResult.auditTrailCompressedBase64?.first ?? "",
                    lowQualityAuditTrailImage: sessionResult.lowQualityAuditTrailCompressedBase64?.first ?? ""
                )
           )
        ) { [weak self] (result: Result<ResponseType, MoyaError>) in
            switch result {
            case .success(let response):
                FaceTecCustomization.setOverrideResultScreenSuccessMessage("Authenticated")

                self?.response = response
                // In v9.2.0+, simply pass in scanResultBlob to the proceedToNextStep function to advance the User flow.
                // scanResultBlob is a proprietary, encrypted blob that controls the logic for what happens next for the User.
                faceScanResultCallback.onFaceScanGoToNextStep(scanResultBlob: response.scanResultBlob)
            case .failure(.underlying(CensoError.biometricValidation(_, let scanResultBlob), _)):
                faceScanResultCallback.onFaceScanGoToNextStep(scanResultBlob: scanResultBlob)
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
        if (self.response != nil) {
            onSuccess(self.response!)
        }
    }
}
