//
//  FacetecError.swift
//  Censo
//
//  Created by Brendan Flood on 9/21/23.
//

import Foundation
import FaceTecSDK
import Sentry

struct FacetecError: Error, Sendable {
    var statusMessage: String
    init(_ message: String) {
        statusMessage = message
        SentrySDK.captureWithTag(error: self, tagValue: "FaceTec")
    }
    init(status: FaceTecSessionStatus) {
        statusMessage = switch (status) {
        case FaceTecSessionStatus.landscapeModeNotAllowed:
            "Your device must be in portrait mode."
        case FaceTecSessionStatus.cameraInitializationIssue:
            "Your camera could not be started."
        case FaceTecSessionStatus.cameraPermissionDenied:
            "You must enable the camera to continue."
        case FaceTecSessionStatus.contextSwitch:
            "Unable to complete, please do not leave the app during the face scan."
        case FaceTecSessionStatus.encryptionKeyInvalid:
            "Unable to continue - encryption key invalid."
        case FaceTecSessionStatus.gracePeriodExceeded:
            "Unable to continue - grace period exceeded."
        case FaceTecSessionStatus.lockedOut:
            "Too many face scan failures, please wait before trying again."
        case FaceTecSessionStatus.lowMemory:
            "Unable to complete the face scan due to insufficient memory. Please close some of your apps and try again."
        case FaceTecSessionStatus.missingGuidanceImages:
            "Unable to continue - missing guidance images."
        case FaceTecSessionStatus.nonProductionModeKeyInvalid:
            "Unable to continue - non-production mode key invalid."
        case FaceTecSessionStatus.nonProductionModeNetworkRequired:
            "Unable to continue - non-production mode network required."
        case FaceTecSessionStatus.reversePortraitNotAllowed:
            "Your device must be in portrait mode."
        case FaceTecSessionStatus.timeout:
            "The face scan took too long, please try again."
        case FaceTecSessionStatus.sessionUnsuccessful, FaceTecSessionStatus.unknownInternalError:
            "Unable to complete the face scan for an unknown reason, please try again."
        default:
            "Unexpected error"
        }
        SentrySDK.captureWithTag(error: self, tagValue: "FaceTec")
    }
}
