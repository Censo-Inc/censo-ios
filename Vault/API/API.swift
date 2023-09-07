//
//  API.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-15.
//

import Foundation
import Moya
import UIKit

enum API {
    case minVersion

    case users
    case createUser(contactType: Contact.`Type`, value: String)
    case contactVerification(verificationId: String, code: String)
    case registerPushToken(String)
    case policies
    case policy(intermediateKey: Base58EncodedPublicKey)
    case createPolicy(intermediateKey: Base58EncodedPublicKey, threshold: Int, guardians: [GuardianInvite])
    case changeGuardians(intermediateKey: Base58EncodedPublicKey, guardians: [GuardianInvite])
    case declineGuardianship(intermediateKey: Base58EncodedPublicKey, participantId: ParticipantId)
    case acceptGuardianship(intermediateKey: Base58EncodedPublicKey, participantId: ParticipantId, encryptedVerificationData: Base64EncodedData)
    case confirmGuardianship(intermediateKey: Base58EncodedPublicKey, participantId: ParticipantId, encryptedShard: Base64EncodedData)
    case confirmShardReceived(intermediateKey: Base58EncodedPublicKey, participantId: ParticipantId, encryptedShard: Base64EncodedData)
    case guardianTasks(participantId: ParticipantId)
    case ownerTasks
    
}

extension API: TargetType {
    var baseURL: URL {
        switch self {
        case .minVersion:
            return Configuration.minVersionURL
        default:
            return Configuration.apiBaseURL
        }
    }

    var path: String {
        switch self {
        case .minVersion:
            return ""
        case .contactVerification(let verificationId, _):
            return "v1/verifications/\(verificationId)/code"
        case .createUser,
             .users:
            return "v1/users"
        case .createPolicy,
             .policies:
            return "v1/policies"
        case .changeGuardians(let intermediateKey, _),
             .policy(let intermediateKey),
             .declineGuardianship(let intermediateKey, _),
             .acceptGuardianship(let intermediateKey, _, _),
             .confirmGuardianship(let intermediateKey, _, _),
             .confirmShardReceived(let intermediateKey, _, _):
            return "v1/policies/\(intermediateKey)"
        case .registerPushToken:
            return "v1/notification-tokens"
        case .ownerTasks:
            return "v1/owner-tasks"
        case .guardianTasks(let participantId):
            return "v1/guardian-tasks/\(participantId)"
        }
    }

    var method: Moya.Method {
        switch self {
        case .minVersion,
             .users,
             .policies,
             .policy,
             .ownerTasks,
             .guardianTasks:
            return .get
        case .createUser,
             .contactVerification,
             .registerPushToken,
             .createPolicy,
             .changeGuardians,
             .declineGuardianship,
             .acceptGuardianship,
             .confirmGuardianship,
             .confirmShardReceived:
            return .post
        }
    }

    var task: Moya.Task {
        switch self {
        case .minVersion,
             .users,
             .policies,
             .policy,
             .ownerTasks,
             .guardianTasks:
            return .requestPlain
        case .createUser(let contactType, let value):
            return .requestJSONEncodable(
                CreateUserApiRequest(contactType: contactType, value: value)
            )
        case .contactVerification(_, let code):
            return .requestJSONEncodable([
                "verificationCode": code
            ])
        case .registerPushToken(let token):
            return .requestJSONEncodable([
                "token": token,
                "deviceType": "Ios"
            ])
        case .createPolicy(let intermediateKey, let threshold, let guardians):
            return .requestJSONEncodable(
                CreatePolicyApiRequest(intermediateKey: intermediateKey, threshold: threshold, guardiansToInvite: guardians)
            )
        case .changeGuardians(_, let guardians):
            return .requestJSONEncodable(
                UpdatePolicyApiRequest(guardiansToInvite: guardians)
            )
        case .declineGuardianship(_, let participantId):
            return .requestJSONEncodable(
                DeclineGuardianshipApiRequest(participantId: participantId)
            )
        case .acceptGuardianship(_, let participantId, let encryptedVerificationData):
            return .requestJSONEncodable(
                AcceptGuardianshipApiRequest(participantId: participantId, encryptedVerificationData: encryptedVerificationData)
            )
        case .confirmGuardianship(_, let participantId, let encryptedShard):
            return .requestJSONEncodable(
                ConfirmGuardianshipApiRequest(participantId: participantId, encryptedShard: encryptedShard)
            )
        case .confirmShardReceived(_, let participantId, let encryptedShard):
            return .requestJSONEncodable(
                ConfirmShardReceiptApiRequest(participantId: participantId, encryptedShard: encryptedShard)
            )
        }
    }

    var headers: [String : String]? {
        return [
            "Content-Type": "application/json",
            "X-IsApi": "true",
            "X-Censo-OS-Version": UIDevice.current.systemVersion,
            "X-Censo-Device-Type": UIDevice.current.systemName,
            "X-Censo-App-Version": Bundle.main.shortVersionString,
            "X-Censo-Device-Public-Key": (try? SecureEnclaveWrapper.deviceKey()?.publicExternalRepresentation().base64EncodedString()) ?? ""
        ]
    }
}

extension Bundle {
    var shortVersionString: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
}
