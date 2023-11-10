//
//  Models.swift
//  Censo
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
    
    struct Password: Encodable {
        var cryptedPassword: Base64EncodedString
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
    
    enum GuardianSetup: Encodable, Decodable {
        case implicitlyOwner(ImplicitlyOwner)
        case externalApprover(ExternalApprover)
        
        struct ImplicitlyOwner: Encodable, Decodable {
            var participantId: ParticipantId
            var label: String
            var guardianPublicKey: Base58EncodedPublicKey
        }
        
        struct ExternalApprover: Encodable, Decodable {
            var participantId: ParticipantId
            var label: String
            var deviceEncryptedTotpSecret: Base64EncodedString
        }
        
        enum GuardianSetupCodingKeys: String, CodingKey {
            case type
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: GuardianSetupCodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            switch type {
            case "ImplicitlyOwner":
                self = .implicitlyOwner(try ImplicitlyOwner(from: decoder))
            case "ExternalApprover":
                self = .externalApprover(try ExternalApprover(from: decoder))
            default:
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid Approver Setup")
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: GuardianSetupCodingKeys.self)
            switch self {
            case .implicitlyOwner(let implicitlyOwner):
                try container.encode("ImplicitlyOwner", forKey: .type)
                try implicitlyOwner.encode(to: encoder)
            case .externalApprover(let externalApprover):
                try container.encode("ExternalApprover", forKey: .type)
                try externalApprover.encode(to: encoder)
            }
        }
    }
    
    struct GuardianShard: Encodable {
        var participantId: ParticipantId
        var encryptedShard: Base64EncodedString
    }
    
    struct OwnerStateResponse: Decodable {
        var ownerState: OwnerState
    }
    
    struct CreatePolicyApiRequest: Encodable {
        var intermediatePublicKey: Base58EncodedPublicKey
        var encryptedMasterPrivateKey: Base64EncodedString
        var masterEncryptionPublicKey: Base58EncodedPublicKey
        var participantId: ParticipantId
        var encryptedShard: Base64EncodedString
        var guardianPublicKey: Base58EncodedPublicKey
        var biometryVerificationId: String
        var biometryData: FacetecBiometry
    }
    
    struct CreatePolicyApiResponse: BiometryVerificationResponse {
        var ownerState: OwnerState
        var scanResultBlob: String
    }
    
    struct CreatePolicyWithPasswordApiRequest: Encodable {
        var intermediatePublicKey: Base58EncodedPublicKey
        var encryptedMasterPrivateKey: Base64EncodedString
        var masterEncryptionPublicKey: Base58EncodedPublicKey
        var participantId: ParticipantId
        var encryptedShard: Base64EncodedString
        var guardianPublicKey: Base58EncodedPublicKey
        var password: Password
    }
    
    struct CreatePolicyWithPasswordApiResponse: Decodable {
        var ownerState: OwnerState
    }
    
    struct SetupPolicyApiRequest: Encodable {
        var threshold: Int
        var guardians: [GuardianSetup]
    }
    
    struct SetupPolicyApiResponse {
        var ownerState: OwnerState
    }
    
    struct ReplacePolicyApiRequest: Encodable {
        var intermediatePublicKey: Base58EncodedPublicKey
        var guardianShards: [GuardianShard]
        var encryptedMasterPrivateKey: Base64EncodedString
        var masterEncryptionPublicKey: Base58EncodedPublicKey
        var signatureByPreviousIntermediateKey: Base64EncodedString
    }
    
    struct ReplacePolicyApiResponse: BiometryVerificationResponse {
        var ownerState: OwnerState
        var scanResultBlob: String
    }
    
    struct ConfirmGuardianApiRequest: Encodable {
        var participantId: ParticipantId
        var keyConfirmationSignature: Base64EncodedString
        var keyConfirmationTimeMillis: UInt64
    }
    
    struct UnlockApiRequest: Encodable {
        var biometryVerificationId: String
        var biometryData: FacetecBiometry
    }
    
    struct UnlockApiResponse: BiometryVerificationResponse {
        var ownerState: OwnerState
        var scanResultBlob: String
    }
    
    struct UnlockWithPasswordApiRequest: Encodable {
        var password: Password
    }
    
    struct UnlockWithPasswordApiResponse: Decodable {
        var ownerState: OwnerState
    }
    
    struct ProlongUnlockApiResponse: Decodable {
        var ownerState: OwnerState
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
    
    struct RequestRecoveryApiRequest : Encodable {
        var intent: Recovery.Intent
    }
    
    struct RequestRecoveryApiResponse : Decodable {
        var ownerState: OwnerState
    }
    
    struct DeleteRecoveryApiResponse : Decodable {
        var ownerState: OwnerState
    }
    
    struct SubmitRecoveryTotpVerificationApiRequest : Encodable {
        var signature: Base64EncodedString
        var timeMillis: UInt64
        var ownerDevicePublicKey: Base58EncodedPublicKey
    }
    
    struct SubmitRecoveryTotpVerificationApiResponse : Decodable {
        var ownerState: OwnerState
    }
    
    struct RetrieveRecoveryShardsApiRequest: Encodable {
        var biometryVerificationId: String
        var biometryData: FacetecBiometry
    }
    
    struct EncryptedShard : Decodable {
        var participantId: ParticipantId
        var encryptedShard: Base64EncodedString
        var isOwnerShard: Bool
    }
    
    struct RetrieveRecoveryShardsApiResponse : BiometryVerificationResponse {
        var ownerState: OwnerState
        var encryptedShards: [EncryptedShard]
        var scanResultBlob: String
    }
    
    struct RetrieveRecoveryShardsWithPasswordApiRequest: Encodable {
        var password: Password
    }

    struct RetrieveRecoveryShardsWithPasswordApiResponse: Decodable {
        var ownerState: OwnerState
        var encryptedShards: [EncryptedShard]
    }
}
