//
//  Models.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-18.
//

import Foundation


extension API {
    struct User: Decodable {
        var userGuid: String
        var ownerState: OwnerState?
    }
    
    struct FacetecBiometry: Encodable {
        var faceScan: String
        var auditTrailImage: String
        var lowQualityAuditTrailImage: String
    }

    struct InitBiometryVerificationApiResponse: Decodable {
        var id: String
        var sessionToken: String
        var productionKeyText: String
        var deviceKeyId: String
        var biometryEncryptionPublicKey: String
    }

    struct ConfirmBiometryVerificationApiRequest: Encodable {
        var faceScan: String
        var auditTrailImage: String
        var lowQualityAuditTrailImage: String
    }

    struct ConfirmBiometryVerificationApiResponse: Decodable {
        var scanResultBlob: String
    }
    
    struct Guardian: Encodable {
        var participantId: ParticipantId
        var encryptedShard: Base64EncodedString
    }
    
    struct OwnerStateResponse: Decodable {
        var ownerState: OwnerState
    }
    
    struct CreatePolicyApiRequest: Encodable {
        var intermediatePublicKey: Base58EncodedPublicKey
        var threshold: Int
        var guardians: [Guardian]
        var encryptedMasterPrivateKey: Base64EncodedString
        var masterEncryptionPublicKey: Base58EncodedPublicKey
        var biometryVerificationId: String
        var biometryData: FacetecBiometry
    }
    
    struct CreatePolicyApiResponse: Decodable {
        var ownerState: OwnerState
        var scanResultBlob: String
    }
    
    struct ConfirmGuardianApiRequest: Encodable {
        var participantId: ParticipantId
        var keyConfirmationSignature: Base64EncodedString
        var keyConfirmationTimeMillis: UInt64
    }
    
    
    struct InviteGuardianApiRequest: Encodable {
        var participantId: ParticipantId
        var deviceEncryptedTotpSecret: Base64EncodedString
    }
    
}
