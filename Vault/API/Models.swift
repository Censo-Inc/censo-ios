//
//  Models.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-18.
//

import Foundation


extension API {
    struct User: Decodable {
        var identityToken: String
        var ownerState: OwnerState
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
        var ownerState: OwnerState
        var scanResultBlob: String
    }
    
    struct GuardianSetup: Encodable {
        var participantId: ParticipantId
        var label: String
    }
    
    struct GuardianShard: Encodable {
        var participantId: ParticipantId
        var encryptedShard: Base64EncodedString
    }
    
    struct OwnerStateResponse: Decodable {
        var ownerState: OwnerState
    }
    
    struct SetupPolicyApiRequest: Encodable {
        var threshold: Int
        var guardians: [GuardianSetup]
        var biometryVerificationId: String
        var biometryData: FacetecBiometry
    }

    struct CreatePolicyApiRequest: Encodable {
        var intermediatePublicKey: Base58EncodedPublicKey
        var guardianShards: [GuardianShard]
        var encryptedMasterPrivateKey: Base64EncodedString
        var masterEncryptionPublicKey: Base58EncodedPublicKey
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
    
    struct UnlockApiRequest: Encodable {
        var biometryVerificationId: String
        var biometryData: FacetecBiometry
    }
    
    struct UnlockApiResponse: Decodable {
        var ownerState: OwnerState
        var scanResultBlob: String
    }
    
    struct LockApiResponse: Decodable {
        var ownerState: OwnerState
    }
    
    struct StoreSecretApiRequest : Encodable {
        var encryptedSeedPhrase: Base64EncodedString
        var seedPhraseHash: String
        var label: String
    }
    
    struct StoreSecretApiResponse : Decodable {
        var ownerState: OwnerState
}
    
    struct DeleteSecretApiResponse : Decodable {
        var ownerState: OwnerState
    }
}
