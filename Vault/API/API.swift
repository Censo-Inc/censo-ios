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
    case createUser(contactType: Contact.ContactType, value: String)
    case contactVerification(verificationId: String, code: String)
    case registerPushToken(String)
    case createPolicy(
        intermediatePublicKey: Base58EncodedPublicKey,
        threshold: Int,
        guardians: [GuardianInvite],
        encryptedMasterPrivateKey: Base64EncodedData,
        masterEncryptionPublicKey: Base58EncodedPublicKey
    )
    case changeGuardians(intermediatePublicKey: Base58EncodedPublicKey, guardians: [GuardianInvite])
    case inviteGuardian(intermediatePublicKey: Base58EncodedPublicKey, participantId: ParticipantId, deviceEncryptedPin: Base64EncodedData)
    case declineGuardianship(intermediatePublicKey: Base58EncodedPublicKey, participantId: ParticipantId)
    case acceptGuardianship(intermediatePublicKey: Base58EncodedPublicKey, participantId: ParticipantId, signature: Base64EncodedData, timeMillis: Int64)
    case confirmGuardianship(intermediatePublicKey: Base58EncodedPublicKey, participantId: ParticipantId, encryptedShard: Base64EncodedData)
    case confirmShardReceived(intermediatePublicKey: Base58EncodedPublicKey, participantId: ParticipantId, encryptedShard: Base64EncodedData)
    case guardianTasks(participantId: ParticipantId)

    case initBiometryVerification
    case confirmBiometryVerification(verificationId: String, faceScan: String, auditTrailImage: String, lowQualityAuditTrailImage: String)
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
            return "v1/contact-verifications/\(verificationId)/code"
        case .createUser,
             .user:
            return "v1/user"
        case .createPolicy:
            return "v1/policies"
        case .changeGuardians(let intermediatePublicKey, _):
            return "v1/policies/\(intermediatePublicKey)"
        case .declineGuardianship(let intermediatePublicKey, let participantId):
            return "v1/policies/\(intermediatePublicKey)/guardian/\(participantId)/decline"
        case .acceptGuardianship(let intermediatePublicKey, let participantId, _, _):
            return "v1/policies/\(intermediatePublicKey)/guardian/\(participantId)/accept"
        case .confirmGuardianship(let intermediatePublicKey, let participantId, _):
            return "v1/policies/\(intermediatePublicKey)/guardian/\(participantId)/confirmation"
        case .confirmShardReceived(let intermediatePublicKey, let participantId, _):
            return "v1/policies/\(intermediatePublicKey)/guardian/\(participantId)/shard-receipt-confirmation"
        case .inviteGuardian(let intermediatePublicKey, let participantId, _):
            return "v1/policies/\(intermediatePublicKey)/guardian/\(participantId)/invitation"
        case .registerPushToken:
            return "v1/notification-tokens"
        case .guardianTasks(let participantId):
            return "v1/guardian-tasks/\(participantId)"
        case .initBiometryVerification:
            return "/v1/biometry-verifications"
        case .confirmBiometryVerification(let verificationId, _, _, _):
            return "v1/biometry-verifications/\(verificationId)/biometry"
        }
    }

    var method: Moya.Method {
        switch self {
        case .minVersion,
             .user,
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
             .confirmShardReceived,
             .inviteGuardian,
             .initBiometryVerification,
             .confirmBiometryVerification:
            return .post
        }
    }

    var task: Moya.Task {
        switch self {
        case .minVersion,
             .declineGuardianship,
             .user,
             .guardianTasks,
             .initBiometryVerification:
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
        case .createPolicy(let intermediatePublicKey, let threshold, let guardians, let encryptedMasterPrivateKey, let masterEncryptionPublicKey):
            return .requestJSONEncodable(
                CreatePolicyApiRequest(
                    intermediatePublicKey: intermediatePublicKey,
                    threshold: threshold,
                    guardiansToInvite: guardians,
                    encryptedMasterPrivateKey: encryptedMasterPrivateKey,
                    masterEncryptionPublicKey: masterEncryptionPublicKey
                )
            )
        case .changeGuardians(_, let guardians):
            return .requestJSONEncodable(
                UpdatePolicyApiRequest(guardiansToInvite: guardians)
            )
        case .acceptGuardianship(_, _, let signature, let timeMillis):
            return .requestJSONEncodable(
                AcceptGuardianshipApiRequest(signature: signature, timeMillis: timeMillis)
            )
        case .confirmGuardianship(_, _, let encryptedShard):
            return .requestJSONEncodable(
                ConfirmGuardianshipApiRequest(encryptedShard: encryptedShard)
            )
        case .confirmShardReceived(_, _, let encryptedShard):
            return .requestJSONEncodable(
                ConfirmShardReceiptApiRequest(encryptedShard: encryptedShard)
            )
        case .inviteGuardian(_, _, let deviceEncryptedPin):
            return .requestJSONEncodable(
                InviteGuardianApiRequest(deviceEncryptedPin: deviceEncryptedPin)
            )
        case .confirmBiometryVerification(_, let faceScan, let auditTrailImage, let lowQualityAuditTrailImage):
            return .requestJSONEncodable(
                ConfirmBiometryVerificationApiRequest(faceScan: faceScan, auditTrailImage: auditTrailImage, lowQualityAuditTrailImage: lowQualityAuditTrailImage)
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
            "X-Censo-Device-Public-Key": (try? SecureEnclaveWrapper.deviceKey()?.publicExternalRepresentation().base58EncodedString()) ?? ""
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
