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

        case user
        case deleteUser
        case signIn(UserCredentials)

        case declineInvitation(InvitationId)
        case acceptInvitation(InvitationId)
        case submitVerification(InvitationId, SubmitGuardianVerificationApiRequest)
        
        case storeRecoveryTotpSecret(ParticipantId, Base64EncodedString)
        case approveOwnerVerification(ParticipantId, Base64EncodedString)
        case rejectOwnerVerification(ParticipantId)
        
        case storeAccessTotpSecret(String, Base64EncodedString)
        case approveAccessVerification(String, Base64EncodedString)
        case rejectAccessVerification(String)
    }
    
    enum GuardianPhase: Codable {
        case waitingForCode
        case waitingForVerification
        case verificationRejected
        case complete
        case recoveryRequested(RecoveryRequested)
        case recoveryVerification(RecoveryVerification)
        case recoveryConfirmation(RecoveryConfirmation)
        
        struct RecoveryRequested: Codable {
            var createdAt: Date
            var recoveryPublicKey: Base58EncodedPublicKey
        }
        
        struct RecoveryVerification: Codable {
            var createdAt: Date
            var recoveryPublicKey: Base58EncodedPublicKey
            var encryptedTotpSecret: Base64EncodedString
        }
        
        struct RecoveryConfirmation: Codable {
            var createdAt: Date
            var recoveryPublicKey: Base58EncodedPublicKey
            var encryptedTotpSecret: Base64EncodedString
            var ownerKeySignature: Base64EncodedString
            var ownerKeySignatureTimeMillis: UInt64
            var ownerPublicKey: Base58EncodedPublicKey
            var guardianEncryptedShard: Base64EncodedString
        }
        
        enum GuardianPhaseCodingKeys: String, CodingKey {
            case type
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: GuardianPhaseCodingKeys.self)
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
            case "RecoveryRequested":
                self = .recoveryRequested(try RecoveryRequested(from: decoder))
            case "RecoveryVerification":
                self = .recoveryVerification(try RecoveryVerification(from: decoder))
            case "RecoveryConfirmation":
                self = .recoveryConfirmation(try RecoveryConfirmation(from: decoder))
            default:
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid GuardianStatus")
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: GuardianPhaseCodingKeys.self)
            switch self {
            case .waitingForCode:
                try container.encode("WaitingForCode", forKey: .type)
            case .waitingForVerification:
                try container.encode("WaitingForVerification", forKey: .type)
            case .verificationRejected:
                try container.encode("VerificationRejected", forKey: .type)
            case .complete:
                try container.encode("Complete", forKey: .type)
            case .recoveryRequested(let phase):
                try container.encode("RecoveryRequested", forKey: .type)
                try phase.encode(to: encoder)
            case .recoveryVerification(let phase):
                try container.encode("RecoveryVerification", forKey: .type)
                try phase.encode(to: encoder)
            case .recoveryConfirmation(let phase):
                try container.encode("RecoveryConfirmation", forKey: .type)
                try phase.encode(to: encoder)
            }
        }
    }
    
    struct GuardianState: Codable {
        var participantId: ParticipantId
        var phase: GuardianPhase
        var invitationId: String?
    }
    
    struct GuardianUser: Decodable {
        var guardianStates: [GuardianState]
    }
    
    struct AcceptInvitationApiResponse: Codable {
        var guardianState: GuardianState
    }
    
    struct SubmitGuardianVerificationApiRequest: Codable {
        var signature: Base64EncodedString
        var timeMillis: UInt64
        var guardianPublicKey: Base58EncodedPublicKey
    }
    
    struct SubmitGuardianVerificationApiResponse: Codable {
        var guardianState: GuardianState
    }
    
    struct OwnerVerificationApiResponse: Codable {
        var guardianStates: [GuardianState]
    }

    struct AttestationChallenge: Decodable {
        var challenge: Base64EncodedString
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
            return "v1/guardianship-invitations/\(id)/decline"
        case .acceptInvitation(let id):
            return "v1/guardianship-invitations/\(id)/accept"
        case .submitVerification(let id, _):
            return "v1/guardianship-invitations/\(id)/verification"
        case .storeRecoveryTotpSecret(let id, _):
            return "v1/recovery/\(id.value)/totp"
        case .approveOwnerVerification(let id, _):
            return "v1/recovery/\(id.value)/approval"
        case .rejectOwnerVerification(let id):
            return "v1/recovery/\(id.value)/rejection"
        case .storeAccessTotpSecret(let id, _):
            return "v1/access/\(id)/totp"
        case .approveAccessVerification(let id, _):
            return "v1/access/\(id)/approval"
        case .rejectAccessVerification(let id):
            return "v1/access/\(id)/rejection"
        }
    }

    var method: Moya.Method {
        switch endpoint {
        case .signIn,
             .declineInvitation,
             .acceptInvitation,
             .submitVerification,
             .storeRecoveryTotpSecret,
             .approveOwnerVerification,
             .rejectOwnerVerification,
             .storeAccessTotpSecret,
             .approveAccessVerification,
             .rejectAccessVerification,
             .registerAttestationObject,
             .attestationChallenge:
            return .post
        case .user:
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
             .attestationChallenge:
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
                "jwtToken": "",
                "identityToken": credentials.userIdentifierHash()
            ])
        case .submitVerification(_, let request):
            return .requestJSONEncodable(request)
        case .storeRecoveryTotpSecret(_, let deviceEncryptedTotpSecret):
            return .requestJSONEncodable([
                "deviceEncryptedTotpSecret": deviceEncryptedTotpSecret
            ])
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
             .storeRecoveryTotpSecret,
             .rejectOwnerVerification,
             .attestationChallenge,
             .registerAttestationObject,
             .storeAccessTotpSecret,
             .rejectAccessVerification:
            return false
        case .deleteUser,
             .submitVerification,
             .approveOwnerVerification,
             .signIn,
             .approveAccessVerification:
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

extension Array where Element == API.GuardianState {
    func forInvite(_ invitationId: String) -> API.GuardianState? {
        return self.first(where: {$0.invitationId == invitationId})
    }
    
    func forParticipantId(_ participantId: ParticipantId) -> API.GuardianState? {
        return self.first(where: {$0.participantId == participantId})
    }
    
    func countExternalApprovers() -> Int {
        self.filter({$0.invitationId != nil}).count
    }
}
