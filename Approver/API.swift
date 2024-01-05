//
//  API.swift
//  Approver
//
//  Created by Ata Namvari on 2023-09-13.
//

import Foundation
import Moya
import SwiftUI
import CryptoKit

typealias InvitationId = String

struct API {
    var deviceKey: DeviceKey
    var endpoint: Endpoint

    enum Endpoint {
        case attestationChallenge
        case registerAttestationObject(challenge: String, attestation: String, keyId: String)
        case attestationKey

        case user
        case deleteUser
        case signIn(UserCredentials)

        case declineInvitation(InvitationId)
        case acceptInvitation(InvitationId)
        case submitVerification(InvitationId, SubmitApproverVerificationApiRequest)
        
        case approveOwnerVerification(ParticipantId, Base64EncodedString)
        case rejectOwnerVerification(ParticipantId)
        
        case storeAccessTotpSecret(String, Base64EncodedString)
        case approveAccessVerification(String, Base64EncodedString)
        case rejectAccessVerification(String)
        
        case labelOwner(ParticipantId, String)
        case createOwnerLoginIdResetToken(ParticipantId)
    }
    
    enum ApproverPhase: Codable, Equatable {
        case waitingForCode
        case waitingForVerification
        case verificationRejected
        case complete
        case accessRequested(AccessRequested)
        case accessVerification(AccessVerification)
        case accessConfirmation(AccessConfirmation)
        
        struct AccessRequested: Codable, Equatable {
            var createdAt: Date
            var accessPublicKey: Base58EncodedPublicKey
        }
        
        struct AccessVerification: Codable, Equatable {
            var createdAt: Date
            var accessPublicKey: Base58EncodedPublicKey
            var encryptedTotpSecret: Base64EncodedString
        }
        
        struct AccessConfirmation: Codable, Equatable {
            var createdAt: Date
            var accessPublicKey: Base58EncodedPublicKey
            var encryptedTotpSecret: Base64EncodedString
            var ownerKeySignature: Base64EncodedString
            var ownerKeySignatureTimeMillis: UInt64
            var ownerPublicKey: Base58EncodedPublicKey
            var approverEncryptedShard: Base64EncodedString
        }
        
        enum ApproverPhaseCodingKeys: String, CodingKey {
            case type
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: ApproverPhaseCodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            switch type {
            case "WaitingForCode":
                self = .waitingForCode
            case "WaitingForVerification":
                self = .waitingForVerification
            case "VerificationRejected":
                self = .verificationRejected
            case "Complete":
                self = .complete
            case "AccessRequested":
                self = .accessRequested(try AccessRequested(from: decoder))
            case "AccessVerification":
                self = .accessVerification(try AccessVerification(from: decoder))
            case "AccessConfirmation":
                self = .accessConfirmation(try AccessConfirmation(from: decoder))
            default:
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid ApproverStatus")
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: ApproverPhaseCodingKeys.self)
            switch self {
            case .waitingForCode:
                try container.encode("WaitingForCode", forKey: .type)
            case .waitingForVerification:
                try container.encode("WaitingForVerification", forKey: .type)
            case .verificationRejected:
                try container.encode("VerificationRejected", forKey: .type)
            case .complete:
                try container.encode("Complete", forKey: .type)
            case .accessRequested(let phase):
                try container.encode("AccessRequested", forKey: .type)
                try phase.encode(to: encoder)
            case .accessVerification(let phase):
                try container.encode("AccessVerification", forKey: .type)
                try phase.encode(to: encoder)
            case .accessConfirmation(let phase):
                try container.encode("AccessConfirmation", forKey: .type)
                try phase.encode(to: encoder)
            }
        }
    }
    
    struct ApproverState: Codable {
        var participantId: ParticipantId
        var phase: ApproverPhase
        var invitationId: String?
        var ownerLabel: String?
        var ownerLoginIdResetToken: OwnerLoginIdResetToken?
    }
    
    struct OwnerLoginIdResetToken: Codable, Equatable, Hashable {
        var value: String
        var url: URL
        
        init(value: String) throws {
            guard let url = URL(string: "\(Configuration.ownerResetUrlScheme)://reset/\(value)") else {
                throw ValueWrapperError.invalidResetToken
            }
            self.value = value
            self.url = url
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            do {
                self = try OwnerLoginIdResetToken(value: try container.decode(String.self))
            } catch {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid login id reset token")
            }
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(value)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(value)
        }
    }
    
    struct ApproverUser: Decodable {
        var approverStates: [ApproverState]
        
        var isActiveApprover: Bool {
            get {
                return approverStates.countActiveApprovers() > 0
            }
        }
    }
    
    struct AcceptInvitationApiResponse: Codable {
        var approverState: ApproverState
    }
    
    struct SubmitApproverVerificationApiRequest: Codable {
        var signature: Base64EncodedString
        var timeMillis: UInt64
        var approverPublicKey: Base58EncodedPublicKey
    }
    
    struct SubmitApproverVerificationApiResponse: Codable {
        var approverState: ApproverState
    }
    
    struct OwnerVerificationApiResponse: Codable {
        var approverStates: [ApproverState]
    }

    struct AttestationChallenge: Decodable {
        var challenge: Base64EncodedString
    }

    struct AttestationKey: Decodable {
        var keyId: String
    }
}

extension API: TargetType {
    var baseURL: URL {
        Configuration.apiBaseURL
    }

    var path: String {
        switch endpoint {
        case .attestationChallenge:
            return "v1/attestation-challenge"
        case .registerAttestationObject:
            return "v1/apple-attestation"
        case .signIn:
            return "v1/sign-in"
        case .user,
             .deleteUser:
            return "v1/user"
        case .declineInvitation(let id):
            return "v1/approvership-invitations/\(id)/decline"
        case .acceptInvitation(let id):
            return "v1/approvership-invitations/\(id)/accept"
        case .submitVerification(let id, _):
            return "v1/approvership-invitations/\(id)/verification"
        case .approveOwnerVerification(let id, _):
            return "v1/access/\(id.value)/approval"
        case .rejectOwnerVerification(let id):
            return "v1/access/\(id.value)/rejection"
        case .storeAccessTotpSecret(let id, _):
            return "v1/access/\(id)/totp"
        case .approveAccessVerification(let id, _):
            return "v1/access/\(id)/approval"
        case .rejectAccessVerification(let id):
            return "v1/access/\(id)/rejection"
        case .attestationKey:
            return "v1/apple-attestation"
        case .labelOwner(let participantId, _):
            return "v1/approvers/\(participantId.value)/owner-label"
        case .createOwnerLoginIdResetToken(let participantId):
            return "v1/login-id-reset-token/\(participantId.value)"
        }
    }

    var method: Moya.Method {
        switch endpoint {
        case .signIn,
             .declineInvitation,
             .acceptInvitation,
             .submitVerification,
             .approveOwnerVerification,
             .rejectOwnerVerification,
             .storeAccessTotpSecret,
             .approveAccessVerification,
             .rejectAccessVerification,
             .registerAttestationObject,
             .attestationChallenge,
             .createOwnerLoginIdResetToken:
            return .post
        case .labelOwner:
            return .put
        case .user,
             .attestationKey:
            return .get
        case .deleteUser:
            return .delete
        }
    }

    var task: Moya.Task {
        switch endpoint {
        case .user,
             .deleteUser,
             .declineInvitation,
             .acceptInvitation,
             .rejectOwnerVerification,
             .rejectAccessVerification,
             .attestationChallenge,
             .attestationKey,
             .createOwnerLoginIdResetToken:
            return .requestPlain
        case .registerAttestationObject(let challenge, let attestation, let keyId):
            #if DEBUG
            return .requestJSONEncodable([
                "deviceType": "IosDebug",
                "challenge": challenge,
                "attestationObject": attestation,
                "keyId": keyId
            ])
            #else
            return .requestJSONEncodable([
                "deviceType": "Ios",
                "challenge": challenge,
                "attestationObject": attestation,
                "keyId": keyId
            ])
            #endif
        case .signIn(let credentials):
            return .requestJSONEncodable([
                "identityToken": credentials.userIdentifierHash()
            ])
        case .submitVerification(_, let request):
            return .requestJSONEncodable(request)
        case .approveOwnerVerification(_, let encryptedShard):
            return .requestJSONEncodable([
                "encryptedShard": encryptedShard
            ])
        case .storeAccessTotpSecret(_, let deviceEncryptedTotpSecret):
            return .requestJSONEncodable([
                "deviceEncryptedTotpSecret": deviceEncryptedTotpSecret
            ])
        case .approveAccessVerification(_, let encryptedShard):
            return .requestJSONEncodable([
                "encryptedShard": encryptedShard
            ])
        case .labelOwner(_, let label):
            return .requestJSONEncodable([
                "label": label
            ])
        }
    }

    var headers: [String : String]? {
        return [
            "Content-Type": "application/json",
            "X-IsApi": "true",
            "X-Censo-OS-Version": UIDevice.current.systemVersion,
            "X-Censo-Device-Type": UIDevice.current.systemName,
            "X-Censo-App-Version": Bundle.main.shortVersionString,
            "X-Censo-App-Identifier": Bundle.main.bundleIdentifier ?? "Unknown",
            "X-Censo-App-Platform": "ios"
        ]
    }

    var requiresAssertion: Bool {
        switch endpoint {
        case .user,
             .declineInvitation,
             .acceptInvitation,
             .rejectOwnerVerification,
             .attestationChallenge,
             .registerAttestationObject,
             .storeAccessTotpSecret,
             .rejectAccessVerification,
             .attestationKey:
            return false
        case .deleteUser,
             .submitVerification,
             .approveOwnerVerification,
             .signIn,
             .approveAccessVerification,
             .labelOwner,
             .createOwnerLoginIdResetToken:
            return true
        }
    }
}

extension Data {
    func base58EncodedString() -> String {
        Base58.encode(bytes)
    }
}

extension Bundle {
    var shortVersionString: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
}

struct APIProviderEnvironmentKey: EnvironmentKey {
    static var defaultValue: MoyaProvider<API> = MoyaProvider(
        plugins: [
            AuthPlugin(),
            ErrorResponsePlugin()
        ]
    )
}

extension EnvironmentValues {
    var apiProvider: MoyaProvider<API> {
        get {
            self[APIProviderEnvironmentKey.self]
        }
        set {
            self[APIProviderEnvironmentKey.self] = newValue
        }
    }
}

extension API.ApproverPhase {
    var isActive: Bool {
        switch self {
        case .complete,
             .accessConfirmation,
             .accessRequested,
             .accessVerification:
            return true
        default:
            return false
        }
    }
}

extension Array where Element == API.ApproverState {
    func forInvite(_ invitationId: String) -> API.ApproverState? {
        return self.first(where: {$0.invitationId == invitationId})
    }
    
    func forParticipantId(_ participantId: ParticipantId) -> API.ApproverState? {
        return self.first(where: {$0.participantId == participantId})
    }
    
    func countActiveApprovers() -> Int {
        self.filter({$0.phase.isActive}).count
    }
    
    func hasOther(_ participantId: ParticipantId) -> Bool {
        return self.filter({$0.participantId != participantId}).count > 0
    }
}

struct Owner: Identifiable {
    var id: String {
        get {
            return participantId.value
        }
    }
    
    var label: String?
    var participantId: ParticipantId
}

extension API.ApproverState {
    func toOwner() -> Owner {
        return Owner(label: self.ownerLabel, participantId: self.participantId)
    }
}

