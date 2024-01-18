//
//  OwnerState.swift
//  Censo
//
//  Created by Brendan Flood on 9/8/23.
//

import Foundation

extension API {
    struct ProspectApprover: Codable, Equatable {
        var invitationId: InvitationId?
        var label: String
        var participantId: ParticipantId
        var status: ApproverStatus
        
        var isConfirmed: Bool {
            get {
                switch (status) {
                case .confirmed: return true
                default: return false
                }
            }
        }
        
        var publicKey: Base58EncodedPublicKey? {
            get {
                switch (status) {
                case .confirmed(let confirmed): return confirmed.approverPublicKey
                case .implicitlyOwner(let implicitlyOwner): return implicitlyOwner.approverPublicKey
                default: return nil
                }
            }
        }
        
        var deviceEncryptedTotpSecret: Base64EncodedString? {
            get {
                switch (status) {
                case .accepted(let accepted):
                    return accepted.deviceEncryptedTotpSecret
                case .verificationSubmitted(let verificationSubmitted):
                    return verificationSubmitted.deviceEncryptedTotpSecret
                case .initial, .confirmed, .declined, .implicitlyOwner, .ownerAsApprover:
                    return nil
                }
            }
        }
        
        var entropy: Base64EncodedString? {
            get {
                return switch status {
                case .ownerAsApprover(let status):
                    status.entropy
                case .implicitlyOwner(let status):
                    status.entropy
                case .initial, .accepted, .confirmed, .declined, .verificationSubmitted:
                    nil
                }
            }
        }
    }

    struct TrustedApprover: Codable {
        var label: String
        var participantId: ParticipantId
        var isOwner: Bool
        var attributes: Attributes

        struct Attributes: Codable {
            var onboardedAt: Date
        }
    }
    
    enum ApproverStatus: Codable, Equatable {
        case initial(Initial)
        case declined
        case accepted(Accepted)
        case verificationSubmitted(VerificationSubmitted)
        case confirmed(Confirmed)
        case ownerAsApprover(OwnerAsApprover)
        case implicitlyOwner(ImplicitlyOwner)
        
        struct Initial: Codable, Equatable {
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
            var approverPublicKey: Base58EncodedPublicKey
            var submittedAt: Date
        }
        
        struct Confirmed: Codable, Equatable {
            var approverKeySignature: Base64EncodedString
            var approverPublicKey: Base58EncodedPublicKey
            var timeMillis: Int64
            var confirmedAt: Date
        }

        struct OwnerAsApprover: Codable, Equatable {
            var entropy: Base64EncodedString
            var confirmedAt: Date
        }
        
        struct ImplicitlyOwner: Codable, Equatable {
            var approverPublicKey: Base58EncodedPublicKey
            var entropy: Base64EncodedString?
            var confirmedAt: Date
        }

        struct Onboarded: Codable {
            var onboardedAt: Date
        }
        
        enum ApproverStatusCodingKeys: String, CodingKey {
            case type
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: ApproverStatusCodingKeys.self)
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
            case "OwnerAsApprover":
                self = .ownerAsApprover(try OwnerAsApprover(from: decoder))
            case "ImplicitlyOwner":
                self = .implicitlyOwner(try ImplicitlyOwner(from: decoder))
            default:
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid ApproverStatus")
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: ApproverStatusCodingKeys.self)
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
            case .ownerAsApprover(let status):
                try container.encode("OwnerAsApprover", forKey: .type)
                try status.encode(to: encoder)
            case .implicitlyOwner(let status):
                try container.encode("ImplicitlyOwner", forKey: .type)
                try status.encode(to: encoder)
            }
        }
    }
    
    struct SeedPhrase: Codable, Equatable {
        var guid: String
        var seedPhraseHash: Base64EncodedString
        var label: String
        var createdAt: Date
    }
    
    struct Vault: Codable {
        var seedPhrases: [SeedPhrase]
        var publicMasterEncryptionKey: Base58EncodedPublicKey
    }

    struct Policy: Codable {
        var createdAt: Date
        var approvers: [TrustedApprover]
        var threshold: UInt
        var encryptedMasterKey: Base64EncodedString
        var intermediateKey: Base58EncodedPublicKey
        var approverKeysSignatureByIntermediateKey: Base64EncodedString
        var masterKeySignature: Base64EncodedString?
        var ownerEntropy: Base64EncodedString?

        var externalApprovers: [TrustedApprover] {
            return approvers
                .filter({ !$0.isOwner })
                .sorted(using: KeyPathComparator(\.attributes.onboardedAt))
        }
        
        var externalApproversCount: Int {
            return externalApprovers.count
        }
        
        var owner: TrustedApprover? {
            return approvers.first { $0.isOwner }
        }
        
        func ownersApproverKeyRecoveryRequired(_ session: Session) -> Bool {
            guard let ownerParticipantId = owner?.participantId else {
                return false
            }
            
            return !session.approverKeyExists(participantId: ownerParticipantId, entropy: ownerEntropy?.data)
        }
    }
    
    enum Access: Codable {
        case anotherDevice(AnotherDevice)
        case thisDevice(ThisDevice)
        
        enum Intent : String, Codable {
            case accessPhrases = "AccessPhrases"
            case replacePolicy = "ReplacePolicy"
            case recoverOwnerKey = "RecoverOwnerKey"
        }
        
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
            var intent: Intent
            
            struct Approval : Codable {
                var participantId: ParticipantId
                var approvalId: String
                var status: Status
                
                enum Status : String, Codable {
                    case initial = "Initial"
                    case waitingForVerification = "WaitingForVerification"
                    case waitingForApproval = "WaitingForApproval"
                    case approved = "Approved"
                    case rejected = "Rejected"
                }
            }
            
            var isApproved: Bool {
                get {
                    return [.available, .timelocked].contains(status)
                }
            }
        }
        
        var isThisDevice: Bool {
            get {
                switch (self) {
                case .thisDevice: return true
                default: return false
                }
            }
        }
        
        enum Status : String, Codable {
            case requested = "Requested"
            case timelocked = "Timelocked"
            case available = "Available"
        }
        
        enum AccessCodingKeys: String, CodingKey {
            case type
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: AccessCodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            switch type {
            case "AnotherDevice":
                self = .anotherDevice(try AnotherDevice(from: decoder))
            case "ThisDevice":
                self = .thisDevice(try ThisDevice(from: decoder))
            default:
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid Access State")
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: AccessCodingKeys.self)
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
    
    struct PolicySetup: Codable, Equatable {
        var approvers: [ProspectApprover]
        var threshold: Int
        
        var owner: ProspectApprover? {
            get {
                return approvers.first(where: {
                    switch ($0.status) {
                    case .implicitlyOwner, .ownerAsApprover:
                        return true
                    default:
                        return false
                    }
                })
            }
        }
        
        var primaryApprover: ProspectApprover? {
            get {
                return explicitApprovers().first
            }
        }
        
        var alternateApprover: ProspectApprover? {
            get {
                let explicitApprovers = explicitApprovers()
                return explicitApprovers.count > 1 ? explicitApprovers[1] : nil
            }
        }
        
        func approverByParticipantId(_ participantId: ParticipantId) -> ProspectApprover? {
            return approvers.first(where: { $0.participantId == participantId })
        }
        
        private func explicitApprovers() -> [ProspectApprover] {
            if let owner = self.owner {
                return approvers.filter({ $0.participantId != owner.participantId })
            } else {
                return []
            }
        }
    }
    
    struct TimelockSetting: Codable, Equatable {
        var defaultTimelockInSeconds: Int
        var currentTimelockInSeconds: Int?
        var disabledAt: Date?
    }

    enum AuthType: String, Codable {
        case none = "None"
        case facetec = "FaceTec"
        case password = "Password"
    }

    enum SubscriptionStatus : String, Codable {
        case none = "None"
        case pending = "Pending"
        case active = "Active"
        case paused = "Paused"
    }
    
    enum OwnerState: Codable {
        case initial(Initial)
        case ready(Ready)
        
        struct Initial: Codable {
            var authType: AuthType
            var entropy: Base64EncodedString
            var subscriptionStatus: SubscriptionStatus
        }
        
        struct Ready: Codable {
            var policy: Policy
            var vault: Vault
            var unlockedForSeconds: UnlockedDuration?
            var policySetup: PolicySetup?
            var access: Access?
            var authType: AuthType
            var subscriptionStatus: SubscriptionStatus
            var timelockSetting: TimelockSetting
        }

        enum OwnerStateCodingKeys: String, CodingKey {
            case type
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: OwnerStateCodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            switch type {
            case "Initial":
                self = .initial(try Initial(from: decoder))
            case "Ready":
                self = .ready(try Ready(from: decoder))
            default:
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid Owner State")
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: OwnerStateCodingKeys.self)
            switch self {
            case .initial(let initial):
                try container.encode("Initial", forKey: .type)
                try initial.encode(to: encoder)
            case .ready(let ready):
                try container.encode("Ready", forKey: .type)
                try ready.encode(to: encoder)
            }
        }
        
        var authType: AuthType {
            get {
                switch self {
                case .initial(let initial):
                    return initial.authType
                case .ready(let ready):
                    return ready.authType
                }
            }
        }

        var subscriptionStatus: SubscriptionStatus {
            get {
                switch (self) {
                case .initial(let initial): return initial.subscriptionStatus
                case .ready(let ready): return ready.subscriptionStatus
                }
            }
        }
        
        var entropy: Base64EncodedString? {
            get {
                return switch (self) {
                case .initial(let initial):
                    initial.entropy
                case .ready(let ready):
                    ready.policy.ownerEntropy
                }
            }
        }

        var onboarding: Bool {
            get {
                switch self {
                case .initial:
                    return true
                case .ready(let ready) where ready.vault.seedPhrases.isEmpty:
                    return true
                default:
                    return false
                }
            }
        }
        
    }
}

extension API.OwnerState.Ready {
    var hasBlockingPhraseAccessRequest: Bool {
        get {
            switch (self.access) {
            case .thisDevice(let access):
                return access.intent == .accessPhrases && (access.status == .available || access.status == .timelocked)
            default:
                break
            }
            return false
        }
    }
}
