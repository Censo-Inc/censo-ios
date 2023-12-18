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
    
    enum ApproverSetup: Encodable, Decodable {
        case implicitlyOwner(ImplicitlyOwner)
        case externalApprover(ExternalApprover)
        
        struct ImplicitlyOwner: Encodable, Decodable {
            var participantId: ParticipantId
            var label: String
            var approverPublicKey: Base58EncodedPublicKey
        }
        
        struct ExternalApprover: Encodable, Decodable {
            var participantId: ParticipantId
            var label: String
            var deviceEncryptedTotpSecret: Base64EncodedString
        }
        
        enum ApproverSetupCodingKeys: String, CodingKey {
            case type
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: ApproverSetupCodingKeys.self)
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
            var container = encoder.container(keyedBy: ApproverSetupCodingKeys.self)
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
    
    struct ApproverShard: Encodable {
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
        var approverPublicKey: Base58EncodedPublicKey
        var approverPublicKeySignatureByIntermediateKey: Base64EncodedString
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
        var approverPublicKey: Base58EncodedPublicKey
        var approverPublicKeySignatureByIntermediateKey: Base64EncodedString
        var password: Password
    }
    
    struct CreatePolicyWithPasswordApiResponse: Decodable {
        var ownerState: OwnerState
    }
    
    struct SetupPolicyApiRequest: Encodable {
        var threshold: Int
        var approvers: [ApproverSetup]
    }
    
    struct SetupPolicyApiResponse {
        var ownerState: OwnerState
    }
    
    struct ReplacePolicyApiRequest: Encodable {
        var intermediatePublicKey: Base58EncodedPublicKey
        var approverKeysSignatureByIntermediateKey: Base64EncodedString
        var approverShards: [ApproverShard]
        var encryptedMasterPrivateKey: Base64EncodedString
        var masterEncryptionPublicKey: Base58EncodedPublicKey
        var signatureByPreviousIntermediateKey: Base64EncodedString
    }
    
    struct ReplacePolicyApiResponse: BiometryVerificationResponse {
        var ownerState: OwnerState
        var scanResultBlob: String
    }
    
    struct ConfirmApproverApiRequest: Encodable {
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
    
    struct StoreSeedPhraseApiRequest : Encodable {
        var encryptedSeedPhrase: Base64EncodedString
        var seedPhraseHash: String
        var label: String
    }
    
    struct StoreSeedPhraseApiResponse : Decodable {
        var ownerState: OwnerState
    }
    
    struct DeleteSeedPhraseApiResponse : Decodable {
        var ownerState: OwnerState
    }
    
    struct RequestAccessApiRequest : Encodable {
        var intent: Access.Intent
    }
    
    struct RequestAccessApiResponse : Decodable {
        var ownerState: OwnerState
    }
    
    struct DeleteAccessApiResponse : Decodable {
        var ownerState: OwnerState
    }
    
    struct SubmitAccessTotpVerificationApiRequest : Encodable {
        var signature: Base64EncodedString
        var timeMillis: UInt64
        var ownerDevicePublicKey: Base58EncodedPublicKey
    }
    
    struct SubmitAccessTotpVerificationApiResponse : Decodable {
        var ownerState: OwnerState
    }
    
    struct RetrieveAccessShardsApiRequest: Encodable {
        var biometryVerificationId: String
        var biometryData: FacetecBiometry
    }
    
    struct EncryptedShard : Decodable {
        var participantId: ParticipantId
        var encryptedShard: Base64EncodedString
        var isOwnerShard: Bool
    }
    
    struct RetrieveAccessShardsApiResponse : BiometryVerificationResponse {
        var ownerState: OwnerState
        var encryptedShards: [EncryptedShard]
        var scanResultBlob: String
    }
    
    struct RetrieveAccessShardsWithPasswordApiRequest: Encodable {
        var password: Password
    }

    struct RetrieveAccessShardsWithPasswordApiResponse: Decodable {
        var ownerState: OwnerState
        var encryptedShards: [EncryptedShard]
    }

    struct AttestationChallenge: Decodable {
        var challenge: Base64EncodedString
    }
    
    struct SubmitPurchaseApiRequest: Encodable {
        var purchase: Purchase
        
        struct Purchase: Encodable {
            var `type`: String = "AppStore"
            var originalTransactionId: String
            var environment: String
        }
    }
    
    struct SubmitPurchaseApiResponse : Decodable {
        var ownerState: OwnerState
    }

    struct AttestationKey: Decodable {
        var keyId: String
    }
    
    struct OwnerProof: Codable {
        var signature: Base64EncodedString
    }
}
