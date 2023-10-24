//
//  Error.swift
//  Vault
//
//  Created by Brendan Flood on 9/27/23.
//

import Foundation

enum CensoError: Swift.Error {
    case validation(String)
    case biometricValidation(message: String, scanResultBlob: String)
    case unexpected(Int)
    case unauthorized
    case underMaintenance
    case invalidIdentifier
    case failedToCreateSignature
    case cannotCreateTotpSecret
    case failedToRecoverPrivateKey
    case failedToRecoverShard
    case verificationFailed
    case failedToDecryptSecrets
    case failedToCreateApproverKey
    case failedToRetrieveApproverKey
    case failedToDecodeSecrets
    case failedToEncodeSecrets
    case failedToReplacePolicy
}

extension CensoError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .validation(let errorMessage):
            return NSLocalizedString(errorMessage, comment: "Validation Error")
        case .biometricValidation(let errorMessage, _):
            return NSLocalizedString(errorMessage, comment: "Biometric Validation Error")
        case .unexpected(let statusCode):
            return NSLocalizedString("Unexpected Error \(statusCode)", comment: "Unexpected Error")
        case .underMaintenance:
            return NSLocalizedString("Censo is currently under maintenance, please try again in a few minutes.", comment: "Under maintenance")
        case .unauthorized:
            return NSLocalizedString("Unauthorized access", comment: "Unauthorized access")
        case .invalidIdentifier:
            return NSLocalizedString("The identifier is not valid.", comment: "Invalid Identifier")
        case .failedToCreateSignature:
            return NSLocalizedString("Failed to create verification signature", comment: "Verification Signature failed")
        case .cannotCreateTotpSecret:
            return NSLocalizedString("Cannot create rotating pin code", comment: "Pin code creation failed")
        case .failedToRecoverPrivateKey:
            return NSLocalizedString("Cannot recover your key", comment: "Key recovery failed")
        case .failedToRecoverShard:
            return NSLocalizedString("Cannot recover owner shard", comment: "shard recovery failed")
        case .verificationFailed:
            return NSLocalizedString("The code you entered is not correct.\nPlease try again", comment: "Verification failed")
        case .failedToDecryptSecrets:
            return NSLocalizedString("Cannot decrypt phrases", comment: "phrase decryption failed")
        case .failedToCreateApproverKey:
            return NSLocalizedString("Failed to generate and store your approver key", comment: "key storage")
        case .failedToRetrieveApproverKey:
            return NSLocalizedString("Failed to retrieve your approver key", comment: "key retrieval")
        case .failedToDecodeSecrets:
            return NSLocalizedString("Cannot decode decrypted phrases", comment: "phrase decoding failed")
        case .failedToEncodeSecrets:
            return NSLocalizedString("Cannot encode phrases", comment: "phrase encoding failed")
        case .failedToReplacePolicy:
            return NSLocalizedString("Failed to replace policy", comment: "policy replacement")
        }
    }
}

extension API {
    struct ResponseError: Decodable {
        var reason: String
        var message: String
        var scanResultBlob: String?
    }
    
    struct ResponseErrors: Decodable {
        var errors: [ResponseError]
    }
}
