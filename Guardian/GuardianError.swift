//
//  GuardianError.swift
//  Guardian
//
//  Created by Ben Holzman on 9/28/23.
//

import Foundation

enum GuardianError: Error {
   case invalidInvitationCode
   case alreadyUsed
   case failedToCreateSignature
   case verificationFailed
}

extension GuardianError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidInvitationCode:
            return NSLocalizedString("The invitation code is not valid.", comment: "Invalid Invitation Code")
        case .alreadyUsed:
            return NSLocalizedString("The invitation code was already used.", comment: "Invitation Code Used")
        case .failedToCreateSignature:
            return NSLocalizedString("Failed to create verification signature", comment: "Verification Signature failed")
        case .verificationFailed:
            return NSLocalizedString("The code you entered is not correct.\nPlease try again", comment: "Verification failed")
        }
    }
}
