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
    
    enum Authentication: Encodable {
        case facetecBiometry(FacetecBiometry)
        case password(Password)
        
        struct FacetecBiometry: Encodable {
            var verificationId: String
            var faceScan: String
            var auditTrailImage: String
            var lowQualityAuditTrailImage: String
        }
        
        struct Password: Encodable {
            var cryptedPassword: Base64EncodedString
        }
        
        enum AuthenticationCodingKeys: String, CodingKey {
            case type
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: AuthenticationCodingKeys.self)
            switch self {
            case .facetecBiometry(let facetecBiometry):
                try container.encode("FacetecBiometry", forKey: .type)
                try facetecBiometry.encode(to: encoder)
            case .password(let password):
                try container.encode("Password", forKey: .type)
                try password.encode(to: encoder)
            }
        }
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
        case externalApprover(ExternalApprover)
        case ownerAsApprover(OwnerAsApprover)
        
        struct OwnerAsApprover: Encodable, Decodable {
            var participantId: ParticipantId
            var label: String
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
            case "OwnerAsApprover":
                self = .ownerAsApprover(try OwnerAsApprover(from: decoder))
            case "ExternalApprover":
                self = .externalApprover(try ExternalApprover(from: decoder))
            default:
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid Approver Setup")
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: ApproverSetupCodingKeys.self)
            switch self {
            case .ownerAsApprover(let ownerAsApprover):
                try container.encode("OwnerAsApprover", forKey: .type)
                try ownerAsApprover.encode(to: encoder)
            case .externalApprover(let externalApprover):
                try container.encode("ExternalApprover", forKey: .type)
                try externalApprover.encode(to: encoder)
            }
        }
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
        var biometryData: Authentication.FacetecBiometry
        var masterKeySignature: Base64EncodedString
    }
    
    struct AuthEnrollmentApiResponse: BiometryVerificationResponse {
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
        var password: Authentication.Password
        var masterKeySignature: Base64EncodedString
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
        var approverPublicKeysSignatureByIntermediateKey: Base64EncodedString
        var approverShards: [ApproverShard]
        var encryptedMasterPrivateKey: Base64EncodedString
        var masterEncryptionPublicKey: Base58EncodedPublicKey
        var signatureByPreviousIntermediateKey: Base64EncodedString
        var masterKeySignature: Base64EncodedString
        
        struct ApproverShard: Encodable {
            var participantId: ParticipantId
            var encryptedShard: Base64EncodedString
        }
    }
    
    struct ReplacePolicyApiResponse : Decodable {
        var ownerState: OwnerState
    }
    
    struct ReplacePolicyShardsApiRequest: Encodable {
        var intermediatePublicKey: Base58EncodedPublicKey
        var approverPublicKeysSignatureByIntermediateKey: Base64EncodedString
        var approverShards: [ApproverShard]
        var encryptedMasterPrivateKey: Base64EncodedString
        var masterEncryptionPublicKey: Base58EncodedPublicKey
        var signatureByPreviousIntermediateKey: Base64EncodedString
        var masterKeySignature: Base64EncodedString
        
        struct ApproverShard: Encodable {
            var participantId: ParticipantId
            var encryptedShard: Base64EncodedString
            var approverPublicKey: Base58EncodedPublicKey
        }
    }
    
    struct ReplacePolicyShardsApiResponse : Decodable {
        var ownerState: OwnerState
    }
    
    struct ConfirmApproverApiRequest: Encodable {
        var participantId: ParticipantId
        var keyConfirmationSignature: Base64EncodedString
        var keyConfirmationTimeMillis: UInt64
    }
    struct CompleteOwnerApprovershipApiRequest: Encodable {
        var participantId: ParticipantId
        var approverPublicKey: Base58EncodedPublicKey
    }
    struct UnlockApiRequest: Encodable {
        var biometryVerificationId: String
        var biometryData: Authentication.FacetecBiometry
    }
    
    struct UnlockApiResponse: BiometryVerificationResponse {
        var ownerState: OwnerState
        var scanResultBlob: String
    }
    
    struct UnlockWithPasswordApiRequest: Encodable {
        var password: Authentication.Password
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
    
    struct TimelockApiResponse: Decodable {
        var ownerState: OwnerState
    }
    
    struct StoreSeedPhraseApiRequest : Encodable {
        var encryptedSeedPhrase: Base64EncodedString
        var seedPhraseHash: String
        var label: String
        var encryptedNotes: SeedPhraseEncryptedNotes?
    }
    
    struct StoreSeedPhraseApiResponse : Decodable {
        var ownerState: OwnerState
    }
    
    struct DeleteSeedPhraseApiResponse : Decodable {
        var ownerState: OwnerState
    }
    
    struct UpdateSeedPhraseMetaInfoApiRequest : Encodable {
        var update: Update
        
        enum Update : Encodable {
            case setLabel(value: String)
            case setNotes(value: SeedPhraseEncryptedNotes)
            case deleteNotes
            
            enum CodingKeys: String, CodingKey {
                case type
                case value
            }
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                switch self {
                case .setLabel(let value):
                    try container.encode("SetLabel", forKey: .type)
                    try container.encode(value, forKey: .value)
                case .setNotes(let value):
                    try container.encode("SetNotes", forKey: .type)
                    try container.encode(value, forKey: .value)
                case .deleteNotes:
                    try container.encode("DeleteNotes", forKey: .type)
                }
            }
        }
    }
    
    struct UpdateSeedPhraseMetaInfoApiResponse : Decodable {
        var ownerState: OwnerState
    }
    
    struct GetSeedPhraseApiResponse : Decodable {
        var encryptedSeedPhrase: Base64EncodedString
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
        var biometryData: Authentication.FacetecBiometry
    }
    
    struct EncryptedShard : Decodable {
        var participantId: ParticipantId
        var encryptedShard: Base64EncodedString
        var isOwnerShard: Bool
        var approverPublicKey: Base58EncodedPublicKey?
        var ownerEntropy: Base64EncodedString?
    }
    
    struct RetrieveAccessShardsApiResponse : BiometryVerificationResponse {
        var ownerState: OwnerState
        var encryptedShards: [EncryptedShard]
        var scanResultBlob: String
    }
    
    struct RetrieveAccessShardsWithPasswordApiRequest: Encodable {
        var password: Authentication.Password
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
    
    struct ResetLoginIdApiRequest: Encodable {
        var identityToken: String
        var resetTokens: [LoginIdResetToken]
        var biometryVerificationId: String
        var biometryData: Authentication.FacetecBiometry
    }
    
    struct ResetLoginIdApiResponse: BiometryVerificationResponse {
        var scanResultBlob: String
    }
    
    struct ResetLoginIdWithPasswordApiRequest: Encodable {
        var identityToken: String
        var resetTokens: [LoginIdResetToken]
        var password: Authentication.Password
    }
    
    struct ResetLoginIdWithPasswordApiResponse: Decodable {
        var ownerState: OwnerState
    }
    
    struct InitiateAuthenticationResetApiResponse: Decodable {
        var ownerState: OwnerState
    }
    
    struct CancelAuthenticationResetApiResponse: Decodable {
        var ownerState: OwnerState
    }
    
    struct ReplaceAuthenticationApiRequest: Encodable {
        var authentication: Authentication
    }
    
    struct ReplacePasswordApiResponse : Decodable {
        var ownerState: OwnerState
    }
    
    struct ReplaceBiometryApiResponse : BiometryVerificationResponse {
        var ownerState: OwnerState
        var scanResultBlob: String
    }
    
    struct InviteBeneficiaryApiRequest: Encodable {
        var label: String
        var deviceEncryptedTotpSecret: Base64EncodedString
    }
    
    struct InviteBeneficiaryApiResponse: Decodable {
        var ownerState: OwnerState
    }
    
    struct AcceptBeneficiaryInvitationApiRequest: Encodable {
        var biometryVerificationId: String
        var biometryData: Authentication.FacetecBiometry
    }

    struct AcceptBeneficiaryInvitationWithPasswordApiRequest: Encodable {
        var password: Authentication.Password
    }
    
    struct AcceptBeneficiaryInvitationWithPasswordApiResponse: Decodable {
        var ownerState: OwnerState
    }
    
    struct SubmitBeneficiaryVerificationApiRequest: Encodable {
        var beneficiaryPublicKey: Base58EncodedPublicKey
        var signature: Base64EncodedString
        var timeMillis: UInt64
    }

    struct SubmitBeneficiaryVerificationApiResponse: Decodable {
        var ownerState: OwnerState
    }
    
    struct BeneficiaryEncryptedKey: Encodable {
        var participantId: ParticipantId
        var encryptedKey: Base64EncodedString
    }
    
    struct ActivateBeneficiaryApiRequest: Encodable {
        var keyConfirmationSignature: Base64EncodedString
        var keyConfirmationTimeMillis: UInt64
        var encryptedKeys: [BeneficiaryEncryptedKey]
    }
    
    struct ActivateBeneficiaryApiResponse: Decodable {
        var ownerState: OwnerState
    }
    
    struct RejectBeneficiaryVerificationApiResponse: Decodable {
        var ownerState: OwnerState
    }
    
    struct UpdateBeneficiaryApproverContactInfoApiRequest: Encodable {
        var approverContacts: [ApproverContactInfo]
        
        struct ApproverContactInfo: Encodable {
            var participantId: ParticipantId
            var beneficiaryKeyEncryptedInfo: Base64EncodedString
            var ownerApproverKeyEncryptedInfo: Base64EncodedString
            var masterKeyEncryptedInfo: Base64EncodedString
        }
    }
    
    struct UpdateBeneficiaryApproverContactInfoApiResponse: Decodable {
        var ownerState: OwnerState
    }

    struct SubmitTakeoverTotpVerificationApiRequest: Encodable {
        var beneficiaryPublicKey: Base58EncodedPublicKey
        var signature: Base64EncodedString
        var timeMillis: UInt64
    }
    
    struct RetrieveTakeoverKeyApiRequest: Encodable {
        var biometryData: Authentication.FacetecBiometry
    }
    
    struct RetrieveTakeoverKeyWithPasswordApiRequest: Encodable {
        var password: Authentication.Password
    }
    
    struct FinalizeTakeoverApiRequest: Encodable {
        var signature: Base64EncodedString
        var timeMillis: UInt64
        var password: Authentication.Password?
    }
    
    struct InitiateTakeoverApiResponse: Decodable {
        var ownerState: OwnerState
    }
    
    struct CancelTakeoverApiResponse: Decodable {
        var ownerState: OwnerState
    }
    
    struct SubmitTakeoverTotpVerificationApiResponse: Decodable {
        var ownerState: OwnerState
    }
    
    struct RetrieveTakeoverKeyApiResponse: Decodable, BiometryVerificationResponse {
        var ownerState: OwnerState
        var encryptedKey: Base64EncodedString
        var scanResultBlob: String
    }
    
    struct RetrieveTakeoverKeyWithPasswordApiResponse: Decodable {
        var ownerState: OwnerState
        var encryptedKey: Base64EncodedString
    }
    
    struct FinalizeTakeoverApiResponse: Decodable {
        var ownerState: OwnerState
    }
}
