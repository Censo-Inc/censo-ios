//
//  OwnerState.swift
//  Vault
//
//  Created by Brendan Flood on 9/8/23.
//

import Foundation

typealias Instant = Date
protocol Guardian {
    var label: String { get set }
    var participantId: ParticipantId { get set }
}

extension API {
    
    enum PolicyGuardian: Codable {
        case prospect(ProspectGuardian)
        case trusted(TrustedGuardian)
        
        struct ProspectGuardian: Guardian, Codable {
            var label: String
            var participantId: ParticipantId
            var status: GuardianStatus
        }
        
        struct TrustedGuardian: Guardian, Codable {
            var label: String
            var participantId: ParticipantId
            var attributes: GuardianStatus.Onboarded
        }
        
        enum GuardianCodingKeys: String, CodingKey {
            case type
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: GuardianCodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            switch type {
            case "Prospect":
                self = .prospect(try ProspectGuardian(from: decoder))
            case "Trusted":
                self = .trusted(try TrustedGuardian(from: decoder))
            default:
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid Guardian \(type)")
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: GuardianCodingKeys.self)
            switch self {
            case .prospect(let status):
                try container.encode("Prospect", forKey: .type)
                try status.encode(to: encoder)
            case .trusted(let status):
                try container.encode("Trusted", forKey: .type)
                try status.encode(to: encoder)
            }
        }
    }
    
    
    enum GuardianStatus: Codable {
        case initial(Initial)
        case invited(Invited)
        case declined(Declined)
        case accepted(Accepted)
        case confirmed(Confirmed)
        case onboarded(Onboarded)
        
        struct Initial: Codable {
            var deviceEncryptedShard: Base64EncodedData
        }
        
        struct Invited: Codable {
            var deviceEncryptedShard: Base64EncodedData
            var deviceEncryptedPin: Base64EncodedData
            var invitedAt: Instant
        }
        
        struct Declined: Codable {
            var deviceEncryptedShard: Base64EncodedData
        }
        
        struct Accepted: Codable {
            var deviceEncryptedShard: Base64EncodedData
            var signature: Base64EncodedData
            var timeMillis: Int64
            var guardianTransportPublicKey: Base58EncodedPublicKey
            var acceptedAt: Instant
        }
        
        struct Confirmed: Codable {
            var guardianTransportEncryptedShard: Base64EncodedData
            var confirmedAt: Instant
        }
        
        struct Onboarded: Codable {
            var guardianEncryptedData: Base64EncodedData
            var passwordHash: Base64EncodedData
            var createdAt: Instant
        }
        
        enum GuardianStatusCodingKeys: String, CodingKey {
            case type
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: GuardianStatusCodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            switch type {
            case "Initial":
                self = .initial(try Initial(from: decoder))
            case "Invited":
                self = .invited(try Invited(from: decoder))
            case "Declined":
                self = .declined(try Declined(from: decoder))
            case "Accepted":
                self = .accepted(try Accepted(from: decoder))
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
            case .initial(let status):
                try container.encode("Initial", forKey: .type)
                try status.encode(to: encoder)
            case .invited(let status):
                try container.encode("Invited", forKey: .type)
                try status.encode(to: encoder)
            case .declined(let status):
                try container.encode("Declined", forKey: .type)
                try status.encode(to: encoder)
            case .accepted(let status):
                try container.encode("Accepted", forKey: .type)
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
        var encryptedSeedPhrase: Base64EncodedData
        var seedPhraseHash: Base64EncodedData
        var label: String
        var createdAt: Instant
    }
    
    struct Vault: Codable {
        var secrets: [VaultSecret]
        var publicMasterEncryptionKey: Base58EncodedPublicKey
    }
    struct Policy<T: Guardian>: Codable where T:Codable {
        var createdAt: Instant
        var guardians: [T]
        var threshold: UInt
        var encryptedMasterKey: Base64EncodedData
        var intermediateKey: Base58EncodedPublicKey
    }
    
    enum OwnerState: Codable {
        case policySetup(PolicySetup)
        case ready(Ready)
        
        struct PolicySetup: Codable {
            var policy: Policy<PolicyGuardian.ProspectGuardian>
            var publicMasterEncryptionKey: Base58EncodedPublicKey
        }
        
        struct Ready: Codable {
            var policy: Policy<PolicyGuardian.TrustedGuardian>
            var vault: Vault
        }
        
        enum OwnerStateCodingKeys: String, CodingKey {
            case type
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: OwnerStateCodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            switch type {
            case "PolicySetup":
                self = .policySetup(try PolicySetup(from: decoder))
            case "Ready":
                self = .ready(try Ready(from: decoder))
            default:
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid Owner State")
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: OwnerStateCodingKeys.self)
            switch self {
            case .policySetup(let policySetup):
                try container.encode("PolicySetup", forKey: .type)
                try policySetup.encode(to: encoder)
            case .ready(let ready):
                try container.encode("Ready", forKey: .type)
                try ready.encode(to: encoder)
            }
        }
    }
    
}

