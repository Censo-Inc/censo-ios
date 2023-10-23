//
//  OwnerState.swift
//  Vault
//
//  Created by Brendan Flood on 9/8/23.
//

import Foundation

extension API {
    struct ProspectGuardian: Codable, Equatable {
        var label: String
        var participantId: ParticipantId
        var status: GuardianStatus
    }

    struct TrustedGuardian: Codable {
        var label: String
        var participantId: ParticipantId
        var attributes: Attributes

        struct Attributes: Codable {
            var onboardedAt: Date
        }
    }
    
    enum GuardianStatus: Codable, Equatable {
        case initial(Initial)
        case declined
        case accepted(Accepted)
        case verificationSubmitted(VerificationSubmitted)
        case confirmed(Confirmed)
        case implicitlyOwner(ImplicitlyOwner)
        
        struct Initial: Codable, Equatable {
            var invitationId: InvitationId
            var deviceEncryptedTotpSecret: Base64EncodedString
        }

        struct Accepted: Codable, Equatable {
            var deviceEncryptedTotpSecret: Base64EncodedString
            var acceptedAt: Date
        }
        
        struct VerificationSubmitted: Codable, Equatable {
            var deviceEncryptedTotpSecret: Base64EncodedString
            var signature: Base64EncodedString
            var timeMillis: Int64
            var guardianPublicKey: Base58EncodedPublicKey
            var submittedAt: Date
        }
        
        struct Confirmed: Codable, Equatable {
            var guardianKeySignature: Base64EncodedString
            var guardianPublicKey: Base58EncodedPublicKey
            var timeMillis: Int64
            var confirmedAt: Date
        }

        struct ImplicitlyOwner: Codable, Equatable {
            var guardianPublicKey: Base58EncodedPublicKey
            var confirmedAt: Date
        }

        struct Onboarded: Codable {
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
                self = .initial(try Initial(from: decoder))
            case "Declined":
                self = .declined
            case "Accepted":
                self = .accepted(try Accepted(from: decoder))
            case "VerificationSubmitted":
                self = .verificationSubmitted(try VerificationSubmitted(from: decoder))
            case "Confirmed":
                self = .confirmed(try Confirmed(from: decoder))
            case "ImplicitlyOwner":
                self = .implicitlyOwner(try ImplicitlyOwner(from: decoder))
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
            case .implicitlyOwner(let status):
                try container.encode("ImplicitlyOwner", forKey: .type)
                try status.encode(to: encoder)
            }
        }
    }
    
    struct VaultSecret: Codable, Equatable {
        var guid: String
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
    
    enum Recovery: Codable {
        case anotherDevice(AnotherDevice)
        case thisDevice(ThisDevice)
        
        struct AnotherDevice: Codable {
            var guid: String
        }
        
        struct ThisDevice : Codable {
            var guid: String
            var status: Status
            var createdAt: Date
            var unlocksAt: Date
            var expiresAt: Date
            var approvals: [Approval]
            var vaultSecretIds: [String]
            
            struct Approval : Codable {
                var participantId: ParticipantId
                var status: Status
                
                enum Status : String, Codable {
                    case initial = "Initial"
                    case waitingForVerification = "WaitingForVerification"
                    case waitingForApproval = "WaitingForApproval"
                    case approved = "Approved"
                    case rejected = "Rejected"
                }
            }
        }
        
        enum Status : String, Codable {
            case requested = "Requested"
            case timelocked = "Timelocked"
            case available = "Available"
        }
        
        enum RecoveryCodingKeys: String, CodingKey {
            case type
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: RecoveryCodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            switch type {
            case "AnotherDevice":
                self = .anotherDevice(try AnotherDevice(from: decoder))
            case "ThisDevice":
                self = .thisDevice(try ThisDevice(from: decoder))
            default:
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid Recovery State")
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: RecoveryCodingKeys.self)
            switch self {
            case .anotherDevice(let anotherDevice):
                try container.encode("AnotherDevice", forKey: .type)
                try anotherDevice.encode(to: encoder)
            case .thisDevice(let thisDevice):
                try container.encode("ThisDevice", forKey: .type)
                try thisDevice.encode(to: encoder)
            }
        }
    }
    
    enum OwnerState: Codable {
        case initial
        case ready(Ready)
        
        struct GuardianSetup: Codable, Equatable {
            var guardians: [ProspectGuardian]
            var threshold: Int
            var unlockedForSeconds: UInt?
        }
        
        struct Ready: Codable {
            var policy: Policy
            var vault: Vault
            var unlockedForSeconds: UnlockedDuration?
            var guardianSetup: GuardianSetup?
            var recovery: Recovery?
        }

        enum OwnerStateCodingKeys: String, CodingKey {
            case type
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: OwnerStateCodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            switch type {
            case "Initial":
                self = .initial
            case "Ready":
                self = .ready(try Ready(from: decoder))
            default:
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid Owner State")
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: OwnerStateCodingKeys.self)
            switch self {
            case .initial:
                try container.encode("Initial", forKey: .type)
            case .ready(let ready):
                try container.encode("Ready", forKey: .type)
                try ready.encode(to: encoder)
            }
        }
        
    }
}
