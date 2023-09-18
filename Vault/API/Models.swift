//
//  Models.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-18.
//

import Foundation


typealias ParticipantId = String
typealias Base58EncodedPublicKey = String
typealias Base64EncodedData = String

extension API {
    struct User: Decodable {
        var contacts: [Contact]
        var biometricVerificationRequired: Bool
        var ownerState: OwnerState?

        var emailContact: API.Contact? {
            contacts.first(where: { $0.contactType == .email })
        }
        
        var phoneContact: API.Contact? {
            contacts.first(where: { $0.contactType == .phone })
        }
    }

    struct Contact: Decodable {
        enum ContactType: String, Codable {
            case email = "Email"
            case phone = "Phone"
        }

        var identifier: String
        var contactType: ContactType
        var value: String
        var verified: Bool
    }

    struct InitiBiometryVerificationApiResponse: Decodable {
        var id: String
        var sessionToken: String
        var productionKeyText: String
        var deviceKeyId: String
        var biometryEncryptionPublicKey: String
        var firstTime: Bool
    }

    struct ConfirmBiometryVerificationApiRequest: Encodable {
        var faceScan: String
        var auditTrailImage: String
        var lowQualityAuditTrailImage: String
    }

    struct ConfirmBiometryVerificationApiResponse: Decodable {
        var scanResultBlob: String
    }
    
    struct GuardianInvite: Encodable {
        var name: String
        var participantId: ParticipantId
        var encryptedShard: Base64EncodedData
    }
    
    struct CreateUserApiRequest: Encodable {
        var contactType: Contact.ContactType
        var value: String
    }
    
    struct CreateUserApiResponse: Decodable {
        var verificationId: String
    }
    
    struct CreatePolicyApiRequest: Encodable {
        var intermediatePublicKey: Base58EncodedPublicKey
        var threshold: Int
        var guardiansToInvite: [GuardianInvite]
        var encryptedMasterPrivateKey: Base64EncodedData
        var masterEncryptionPublicKey: Base58EncodedPublicKey
    }
    
    struct UpdatePolicyApiRequest: Encodable {
        var guardiansToInvite: [GuardianInvite]
    }
    
    struct AcceptGuardianshipApiRequest: Encodable {
        var signature: Base64EncodedData
        var timeMillis: Int64
    }
    
    struct ConfirmGuardianshipApiRequest: Encodable {
        var encryptedShard: Base64EncodedData
    }
    
    struct ConfirmShardReceiptApiRequest: Encodable {
        var encryptedShard: Base64EncodedData
    }
    
    struct InviteGuardianApiRequest: Encodable {
        var deviceEncryptedPin: Base64EncodedData
    }
    
    struct OwnerInfo: Decodable {
        var name: String
        var devicePublicKey: Base58EncodedPublicKey
    }
    
    struct InvitePending: Decodable {
        var ownerInfo: OwnerInfo
        var intermediatePublicKey: Base58EncodedPublicKey
    }
    
    struct ShardAvailable: Decodable {
        var ownerInfo: OwnerInfo
        var intermediatePublicKey: Base58EncodedPublicKey
        var shardData: Base64EncodedData
    }
    
    enum GuardianTask: Decodable {
        case invitePending(InvitePending)
        case shardAvailable(ShardAvailable)

        enum GuardianTaskCodingKeys: String, CodingKey {
            case type
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: GuardianTaskCodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            switch type {
            case "InvitePending":
                self = .invitePending(try InvitePending(from: decoder))
            case "ShardAvailable":
                self = .shardAvailable(try ShardAvailable(from: decoder))
            default:
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid Guardian Task")
            }
        }
    }

}
