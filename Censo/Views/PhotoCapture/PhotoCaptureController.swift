//
//  PhotoCaptureController.swift
//  Censo
//
//  Created by Brendan Flood on 1/18/24.
//

import Foundation
import AVFoundation
import UIKit

class PhotoCaptureController: NSObject, ObservableObject {
    @Published fileprivate(set) var state: CaptureState = .stopped
    @Published var photo: UIImage?

    private let captureDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: .video, position: .back)
    private let videoQueue = DispatchQueue(label: "video-capture-queue")

    enum CaptureState {
        case starting
        case notAvailable(Error)
        case running(AVCaptureSession, AVCapturePhotoOutput)
        case stopped
        case readyToStart
    }

    enum CaptureDeviceError: Error {
        case noCaptureDevice
        case deviceUnableToCapturePhoto
    }

    func restartCapture() {
        guard let device = captureDevice else {
            state = .notAvailable(CaptureDeviceError.noCaptureDevice)
            return
        }

        videoQueue.async { [weak self] in
            do {
                let session = AVCaptureSession()
                let videoInput = try AVCaptureDeviceInput(device: device)
                let photoOutput = AVCapturePhotoOutput()
                let videoOutput = AVCaptureVideoDataOutput()

                guard session.canAddInput(videoInput),
                      session.canAddOutput(photoOutput),
                      session.canAddOutput(videoOutput) else {
                    DispatchQueue.main.async {
                        self?.state = .notAvailable(CaptureDeviceError.deviceUnableToCapturePhoto)
                    }
                    return
                }

                session.addInput(videoInput)
                session.addOutput(photoOutput)
                session.addOutput(videoOutput)

                session.startRunning()

                DispatchQueue.main.async {
                    self?.state = .running(session, photoOutput)
                }
            } catch {
                DispatchQueue.main.async {
                    self?.state = .notAvailable(error)
                }
            }

        }
    }

    func stopCapture() {
        switch state {
        case .running(let session, _):
            videoQueue.async { [weak self] in
                session.stopRunning()

                DispatchQueue.main.async {
                    self?.state = .stopped
                }
            }
        default:
            break
        }
    }

    func capturePhoto() {
        switch state {
        case .running(_, let photoOutput):
            videoQueue.async {
                if let photoOutputConnection = photoOutput.connection(with: .video) {
                    photoOutputConnection.videoOrientation = self.orientation()
                }

                let settings = AVCapturePhotoSettings()
                photoOutput.capturePhoto(with: settings, delegate: self)
            }
        default:
            break
        }
    }
    
    func readyToStart() {
        self.state = .readyToStart
    }

    private func orientation() -> AVCaptureVideoOrientation {
        switch UIDevice.current.orientation {
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
}


extension PhotoCaptureController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard
            error == nil,
            let dataImage = photo.fileDataRepresentation()
            else {
                fatalError("Unable to capture the photo due to an error")
        }

        DispatchQueue.main.async {
            self.photo = UIImage(data: dataImage)!.cropsToSquare()!
        }
    }
}

extension UIImage {
    func cropsToSquare() -> UIImage? {
        if let image = self.cgImage {
            let refWidth = CGFloat((image.width))
            let refHeight = CGFloat((image.height))
            let cropSize = min(refWidth, refHeight) //refWidth > refHeight ? refHeight : refWidth

            let x = (refWidth - cropSize) / 2.0
            let y = (refHeight - cropSize) / 2.0

            let cropRect = CGRect(x: x, y: y, width: cropSize, height: cropSize)
            let imageRef = image.cropping(to: cropRect)
            let cropped = UIImage(cgImage: imageRef!, scale: 0.0, orientation: self.imageOrientation)
            return cropped
        }
        return nil
    }
}
