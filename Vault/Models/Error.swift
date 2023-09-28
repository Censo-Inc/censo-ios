//
//  Error.swift
//  Vault
//
//  Created by Brendan Flood on 9/27/23.
//

import Foundation

enum CensoError: Swift.Error {
    case validation(String)
    case unexpected(Int)
    case unauthorized
    case underMaintenance
    case invalidInvitationCode
    case failedToCreateSignature
}

extension CensoError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .validation(let errorMessage):
            return NSLocalizedString(errorMessage, comment: "Validation Error")
        case .unexpected(let statusCode):
            return NSLocalizedString("Unexpected Error \(statusCode)", comment: "Unexpected Error")
        case .underMaintenance:
            return NSLocalizedString("Censo is currently under maintenance, please try again in a few minutes.", comment: "Under maintenance")
        case .unauthorized:
            return NSLocalizedString("Unauthorized access", comment: "Unauthorized access")
        case .invalidInvitationCode:
            return NSLocalizedString("The invitation code is not valid.", comment: "Invalid Invitation Code")
        case .failedToCreateSignature:
            return NSLocalizedString("Failed to create verification signature", comment: "Verification Signature failed")

        }
    }
}

extension API {
    struct ResponseError: Decodable {
        var reason: String
        var message: String
    }
    
    struct ResponseErrors: Decodable {
        var errors: [ResponseError]
    }
}
