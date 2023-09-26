//
//  OwnerState.swift
//  Vault
//
//  Created by Brendan Flood on 9/8/23.
//

import Foundation

extension API {
    struct ProspectGuardian: Codable {
        var label: String
        var invitationId: String?
        var deviceEncryptedTotpSecret: Base64EncodedString?
        var participantId: ParticipantId
        var status: GuardianStatus
    }

    struct TrustedGuardian: Codable {
        var label: String
        var participantId: ParticipantId
        var attributes: GuardianStatus.Onboarded
    }
    
    enum GuardianStatus: Codable {
        case initial
        case invited(Invited)
        case declined
        case accepted(Accepted)
        case verificationSubmitted(VerificationSubmitted)
        case confirmed(Confirmed)
        case onboarded(Onboarded)
        
        struct Invited: Codable {
            var invitedAt: Date
        }

        struct Accepted: Codable {
            var acceptedAt: Date
        }
        
        struct VerificationSubmitted: Codable {
            var signature: Base64EncodedString
            var timeMillis: Int64
            var guardianPublicKey: Base58EncodedPublicKey
            var verificationStatus: VerificationStatus
            var submittedAt: Date
        }
        
        struct Confirmed: Codable {
            var guardianKeySignature: Base64EncodedString
            var guardianPublicKey: Base58EncodedPublicKey
            var timeMillis: Int64
            var confirmedAt: Date
        }
        
        struct Onboarded: Codable {
            var guardianEncryptedShard: Base64EncodedString
            var onboardedAt: Date
        }
        
        enum GuardianStatusCodingKeys: String, CodingKey {
            case type
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: GuardianStatusCodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            switch type {
            case "Initial":
                self = .initial
            case "Invited":
                self = .invited(try Invited(from: decoder))
            case "Declined":
                self = .declined
            case "Accepted":
                self = .accepted(try Accepted(from: decoder))
            case "VerificationSubmitted":
                self = .verificationSubmitted(try VerificationSubmitted(from: decoder))
            case "Confirmed":
                self = .confirmed(try Confirmed(from: decoder))
            case "Onboarded":
                self = .onboarded(try Onboarded(from: decoder))
            default:
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid GuardianStatus")
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: GuardianStatusCodingKeys.self)
            switch self {
            case .initial:
                try container.encode("Initial", forKey: .type)
            case .invited(let status):
                try container.encode("Invited", forKey: .type)
                try status.encode(to: encoder)
            case .declined:
                try container.encode("Declined", forKey: .type)
            case .accepted(let status):
                try container.encode("Accepted", forKey: .type)
                try status.encode(to: encoder)
            case .verificationSubmitted(let status):
                try container.encode("VerificationSubmitted", forKey: .type)
                try status.encode(to: encoder)
            case .confirmed(let status):
                try container.encode("Confirmed", forKey: .type)
                try status.encode(to: encoder)
            case .onboarded(let status):
                try container.encode("Onboarded", forKey: .type)
                try status.encode(to: encoder)
            }
        }
    }
    
    struct VaultSecret: Codable, Equatable {
        var encryptedSeedPhrase: Base64EncodedString
        var seedPhraseHash: Base64EncodedString
        var label: String
        var createdAt: Date
    }
    
    struct Vault: Codable {
        var secrets: [VaultSecret]
        var publicMasterEncryptionKey: Base58EncodedPublicKey
    }

    struct Policy: Codable {
        var createdAt: Date
        var guardians: [TrustedGuardian]
        var threshold: UInt
        var encryptedMasterKey: Base64EncodedString
        var intermediateKey: Base58EncodedPublicKey
    }
    
    enum OwnerState: Codable {
        case guardianSetup(GuardianSetup)
        case ready(Ready)
        
        struct GuardianSetup: Codable {
            var guardians: [ProspectGuardian]
        }
        
        struct Ready: Codable {
            var policy: Policy
            var vault: Vault
            var unlockedForSeconds: UInt?
        }
        
        enum OwnerStateCodingKeys: String, CodingKey {
            case type
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: OwnerStateCodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            switch type {
            case "GuardianSetup":
                self = .guardianSetup(try GuardianSetup(from: decoder))
            case "Ready":
                self = .ready(try Ready(from: decoder))
            default:
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid Owner State")
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: OwnerStateCodingKeys.self)
            switch self {
            case .guardianSetup(let guardianSetup):
                try container.encode("GuardianSetup", forKey: .type)
                try guardianSetup.encode(to: encoder)
            case .ready(let ready):
                try container.encode("Ready", forKey: .type)
                try ready.encode(to: encoder)
            }
        }
    }
}
