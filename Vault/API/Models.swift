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
        var name: String
        var contacts: [Contact]
    }

    struct Contact: Decodable {
        enum `Type`: String, Decodable {
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
        var guardianId: String?
    }
    
    struct CreatePolicyApiRequest: Encodable {
        var policyKey: Base58EncodedPublicKey
        var threshold: Int
        var guardiansToInvite: [GuardianInvite]
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
    
    struct GetPolicyApiResponse: Decodable {
        enum `Status`: String, Decodable {
            case pending   = "Pending"
            case activate  = "Active"
        }
        var status: `Status`
        var policyKey: Base58EncodedPublicKey
        var threshold: Int
        var guardians: [Guardian]
    }
    
    struct AcceptGuardianshipApiRequest: Encodable {
        var participantId: ParticipantId
        var encryptedVerificationData: Base64EncodedData
    }
    
    struct DeclineGuardianshipApiRequest: Encodable {
        var participantId: ParticipantId
    }
    
    struct ConfirmGuardianshipApiRequest: Encodable {
        var participantId: ParticipantId
        var encryptedShard: Base64EncodedData
    }
    
    struct ConfirmShardReceiptApiRequest: Encodable {
        var participantId: ParticipantId
        var encryptedShard: Base64EncodedData
    }
    
    struct OwnerInfo: Decodable {
        var name: String
        var devicePublicKey: Base58EncodedPublicKey
    }

    struct GuardianInfo: Decodable {
        var name: String
        var participantId: ParticipantId
    }
    
    struct InvitePending: Decodable {
        var ownerInfo: OwnerInfo
        var policyKey: Base58EncodedPublicKey
    }
    
    struct ShardAvailable: Decodable {
        var ownerInfo: OwnerInfo
        var policyKey: Base58EncodedPublicKey
        var shardData: Base64EncodedData
    }
    
    struct GuardianDeclined: Decodable {
        var guardianInfo: GuardianInfo
        var policyKey: Base58EncodedPublicKey
    }
    
    struct GuardianAccepted: Decodable {
        var guardianInfo: GuardianInfo
        var policyKey: Base58EncodedPublicKey
        var encryptedVerificationData: Base64EncodedData
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
    
    enum OwnerTask: Decodable {
        case guardianDeclined(GuardianDeclined)
        case guardianAccepted(GuardianAccepted)

        enum OwnerTaskCodingKeys: String, CodingKey {
            case type
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: OwnerTaskCodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            switch type {
            case "GuardianDeclined":
                self = .guardianDeclined(try GuardianDeclined(from: decoder))
            case "GuardianAccepted":
                self = .guardianAccepted(try GuardianAccepted(from: decoder))
            default:
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid Owner Task")
            }
        }

    }

}
