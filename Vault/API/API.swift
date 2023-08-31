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

    case user
    case createDevice
    case createUser(name: String)
    case createContact(type: Contact.`Type`, value: String)
    case verifyContact(Contact, code: String)
    case registerPushToken(String)
    case policies
    case policy(policyKey: Base58EncodedPublicKey)
    case createPolicy(policyKey: Base58EncodedPublicKey, threshold: Int, guardians: [GuardianInvite])
    case changeGuardians(policyKey: Base58EncodedPublicKey, guardians: [GuardianInvite])
    case declineGuardianship(policyKey: Base58EncodedPublicKey, participantId: ParticipantId)
    case acceptGuardianship(policyKey: Base58EncodedPublicKey, participantId: ParticipantId, encryptedVerificationData: Base64EncodedData)
    case confirmGuardianship(policyKey: Base58EncodedPublicKey, participantId: ParticipantId, encryptedShard: Base64EncodedData)
    case confirmShardReceived(policyKey: Base58EncodedPublicKey, participantId: ParticipantId, encryptedShard: Base64EncodedData)
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
        case .createContact:
            return "v1/contacts"
        case .createUser,
             .user:
            return "v1/user"
        case .createPolicy,
             .policies:
            return "v1/policies"
        case .changeGuardians(let policyKey, _),
             .policy(let policyKey),
             .declineGuardianship(let policyKey, _),
             .acceptGuardianship(let policyKey, _, _),
             .confirmGuardianship(let policyKey, _, _),
             .confirmShardReceived(let policyKey, _, _):
            return "v1/policies/\(policyKey)"
        case .verifyContact(let contact, _):
            return "v1/contacts/\(contact.identifier)/verification-code"
        case .createDevice:
            return "v1/device"
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
             .user,
             .policies,
             .policy,
             .ownerTasks,
             .guardianTasks:
            return .get
        case .createUser,
             .createContact,
             .verifyContact,
             .createDevice,
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
             .user,
             .createDevice,
             .policies,
             .policy,
             .ownerTasks,
             .guardianTasks:
            return .requestPlain
        case .createUser(let name):
            return .requestJSONEncodable([
                "name": name
            ])
        case .createContact(let type, let value):
            return .requestJSONEncodable([
                "contactType": type.rawValue,
                "value": value
            ])
        case .verifyContact(_, let code):
            return .requestJSONEncodable([
                "verificationCode": code
            ])
        case .registerPushToken(let token):
            return .requestJSONEncodable([
                "token": token,
                "deviceType": "Ios"
            ])
        case .createPolicy(let policyKey, let threshold, let guardians):
            return .requestJSONEncodable(
                CreatePolicyApiRequest(policyKey: policyKey, threshold: threshold, guardiansToInvite: guardians)
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
