//
//  API.swift
//  Guardian
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
    }
    
    enum GuardianPhase: Codable {
        case waitingForCode(WaitingForCode)
        case waitingForConfirmation(WaitingForConfirmation)
        case complete
        
        struct WaitingForConfirmation: Codable {
            var invitationId: String
            var verificationStatus: VerificationStatus
        }
        
        struct WaitingForCode: Codable {
            var invitationId: String
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
            case "WaitingForConfirmation":
                self = .waitingForConfirmation(try WaitingForConfirmation(from: decoder))
            case "Complete":
                self = .complete
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
            case .waitingForConfirmation(let phase):
                try container.encode("WaitingForConfirmation", forKey: .type)
                try phase.encode(to: encoder)
            case .complete:
                try container.encode("Complete", forKey: .type)
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
        }
    }

    var method: Moya.Method {
        switch endpoint {
        case .signIn,
             .declineInvitation,
             .acceptInvitation,
             .submitVerification,
             .registerPushToken:
            return .post
        case .user:
            return .get
        }
    }

    var task: Moya.Task {
        switch endpoint {
        case .user,
             .declineInvitation,
             .acceptInvitation:
            return .requestPlain
        case .signIn(let credentials):
            return .requestJSONEncodable(credentials)
        case .submitVerification(_, let request):
            return .requestJSONEncodable(request)
        case .registerPushToken(let token):
            return .requestJSONEncodable([
                "token": token,
                "deviceType": "Ios"
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
            "X-Censo-App-Identifer": Bundle.main.bundleIdentifier ?? "Unknown"
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
            case .waitingForConfirmation(let state):
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
}
