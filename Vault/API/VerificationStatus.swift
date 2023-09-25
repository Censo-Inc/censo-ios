//
//  VerificationStatus.swift
//  Vault
//
//  Created by Brendan Flood on 9/21/23.
//

import SwiftUI

enum VerificationStatus: String, Codable {
    case notSubmitted = "NotSubmitted"
    case waitingForVerification = "WaitingForVerification"
    case verified = "Verified"
    case rejected = "Rejected"
}
