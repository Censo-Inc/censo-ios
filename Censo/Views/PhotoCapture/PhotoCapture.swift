//
//  PhotoCapture.swift
//  Censo
//
//  Created by Brendan Flood on 1/18/24.
//

import SwiftUI

struct PhotoCapture<Submission>: View where Submission : View {
    typealias RetakeClosure = () -> Void

    @StateObject private var controller = PhotoCaptureController()

    var onBack: () -> Void
    @ViewBuilder var submission: (UIImage, @escaping RetakeClosure) -> Submission

    var body: some View {
        switch (controller.photo, controller.state) {
        case (.some(let uiImage), _):
            submission(uiImage) {
                controller.photo = nil
            }
        case (.none, .notAvailable):
            CameraNotAvailable()
        case (.none, .running(let session, _)):
            TakeSeedPhoto(
                onTakePhoto: controller.capturePhoto,
                onBack: controller.stopCapture
            ) {
                CameraPreview(session: session)
            }
        case (.none, .starting):
            ProgressView()
        case (.none, .readyToStart):
            ProgressView()
                .onAppear {
                    controller.restartCapture()
                }
        case (.none, .stopped):
            SeedPhotoIntro(
                onReadyToStart: controller.readyToStart,
                onBack: onBack
            )
        }
    }
}



