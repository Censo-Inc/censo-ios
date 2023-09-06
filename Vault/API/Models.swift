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
        // this may change once Ievgen adds to API, but this roughly matches what was discussed
        enum FaceVerificatonStatus: String, Decodable {
            case notEnrolled = "NotEnrolled"   // user associated with the device has no face enrolled
            case enrolled    = "NotAuthorized" // user associated with the device has a face enrolled but not authorized for the device
            case authorized  = "Authorized"    // this device passed face authorization
        }

        var contacts: [Contact]
        var faceVerificationStatus: `FaceVerificatonStatus`
        var encryptedData: Base64EncodedData?
    }

    struct Contact: Decodable {
        enum `Type`: String, Codable {
            case email = "Email"
            case phone = "Phone"
        }

        var identifier: String
        var contactType: `Type`
        var value: String
        var verified: Bool
    }
    
    struct GuardianInvite: Encodable {
        var name: String
        var participantId: ParticipantId
        var encryptedShard: Base64EncodedData
    }
    
    struct CreateUserApiRequest: Encodable {
        var contactType: Contact.`Type`
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
    
    struct Guardian: Decodable {
        enum `Status`: String, Decodable {
            case invited   = "Invited"
            case declined  = "Declined"
            case accepted  = "Accepted"
            case confirmed = "Confirmed"
            case active    = "Active"
        }
    
        var id: String
        var name: String
        var participantId: ParticipantId
        var status: `Status`
        var encryptedVerificationData: Base64EncodedData?
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
