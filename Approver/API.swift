//
//  API.swift
//  Approver
//
//  Created by Ata Namvari on 2023-09-13.
//

import Foundation
import Moya
import SwiftUI

typealias InvitationId = String

struct API {
    var deviceKey: DeviceKey
    var endpoint: Endpoint

    enum Endpoint {
        case user
        case signIn(UserCredentials)
        case registerPushToken(String)

        case declineInvitation(InvitationId)
        case acceptInvitation(InvitationId)
        case submitVerification(InvitationId, SubmitGuardianVerificationApiRequest)
        
        case storeRecoveryTotpSecret(ParticipantId, Base64EncodedString)
        case approveOwnerVerification(ParticipantId, Base64EncodedString)
        case rejectOwnerVerification(ParticipantId)
    }
    
    enum GuardianPhase: Codable {
        case waitingForCode(WaitingForCode)
        case waitingForVerification(WaitingForVerification)
        case verificationRejected(VerificationRejected)
        case complete
        case recoveryRequested(RecoveryRequested)
        case recoveryVerification(RecoveryVerification)
        case recoveryConfirmation(RecoveryConfirmation)
        
        struct WaitingForVerification: Codable {
            var invitationId: String
        }
        
        struct WaitingForCode: Codable {
            var invitationId: String
        }
        
        struct VerificationRejected: Codable {
            var invitationId: String
        }
        
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
                self = .waitingForCode(try WaitingForCode(from: decoder))
            case "WaitingForVerification":
                self = .waitingForVerification(try WaitingForVerification(from: decoder))
            case "VerificationRejected":
                self = .verificationRejected(try VerificationRejected(from: decoder))
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
            case .waitingForCode(let phase):
                try container.encode("WaitingForCode", forKey: .type)
                try phase.encode(to: encoder)
            case .waitingForVerification(let phase):
                try container.encode("WaitingForVerification", forKey: .type)
                try phase.encode(to: encoder)
            case .verificationRejected(let phase):
                try container.encode("VerificationRejected", forKey: .type)
                try phase.encode(to: encoder)
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
}

extension API: TargetType {
    var baseURL: URL {
        Configuration.apiBaseURL
    }

    var path: String {
        switch endpoint {
        case .signIn:
            return "v1/sign-in"
        case .user:
            return "v1/user"
        case .declineInvitation(let id):
            return "v1/guardianship-invitations/\(id)/decline"
        case .acceptInvitation(let id):
            return "v1/guardianship-invitations/\(id)/accept"
        case .submitVerification(let id, _):
            return "v1/guardianship-invitations/\(id)/verification"
        case .registerPushToken:
            return "v1/notification-tokens"
        case .storeRecoveryTotpSecret(let id, _):
            return "v1/recovery/\(id.value)/totp"
        case .approveOwnerVerification(let id, _):
            return "v1/recovery/\(id.value)/approval"
        case .rejectOwnerVerification(let id):
            return "v1/recovery/\(id.value)/rejection"
        }
    }

    var method: Moya.Method {
        switch endpoint {
        case .signIn,
             .declineInvitation,
             .acceptInvitation,
             .submitVerification,
             .registerPushToken,
             .storeRecoveryTotpSecret,
             .approveOwnerVerification,
             .rejectOwnerVerification:
            return .post
        case .user:
            return .get
        }
    }

    var task: Moya.Task {
        switch endpoint {
        case .user,
             .declineInvitation,
             .acceptInvitation,
             .rejectOwnerVerification:
            return .requestPlain
        case .signIn(let credentials):
            return .requestJSONEncodable(credentials)
        case .submitVerification(_, let request):
            return .requestJSONEncodable(request)
        case .registerPushToken(let token):
            #if DEBUG
            return .requestJSONEncodable([
                "deviceType": "IosDebug",
                "token": token
            ])
            #else
            return .requestJSONEncodable([
                "deviceType": "Ios",
                "token": token,
            ])
            #endif
        case .storeRecoveryTotpSecret(_, let deviceEncryptedTotpSecret):
            return .requestJSONEncodable([
                "deviceEncryptedTotpSecret": deviceEncryptedTotpSecret
            ])
        case .approveOwnerVerification(_, let encryptedShard):
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
            "X-Censo-App-Identifier": Bundle.main.bundleIdentifier ?? "Unknown"
        ]
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
    }
}

extension Array where Element == API.GuardianState {
    func forInvite(_ invitationId: String) -> API.GuardianState? {
        if self.isEmpty {
            return nil
        }
        for guardianState in self {
            switch(guardianState.phase) {
            case .waitingForCode(let state):
                if state.invitationId == invitationId {
                    return guardianState
                }
            case .waitingForVerification(let state):
                if state.invitationId == invitationId {
                    return guardianState
                }
            case .verificationRejected(let state):
                if state.invitationId == invitationId {
                    return guardianState
                }
            case .complete:
                return guardianState
            default:
                break
            }
        }
        return nil
    }
    
    func forParticipantId(_ participantId: ParticipantId) -> API.GuardianState? {
        return self.first(where: {$0.participantId == participantId})
    }
}
