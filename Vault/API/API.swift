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

    case createGuardian(name: String)
    case deleteGuardian(ParticipantId)
    case inviteGuardian(ParticipantId)
    case confirmGuardian(ConfirmGuardianRequest)

    case createPolicy(CreatePolicyApiRequest)

    case initBiometryVerification
    case confirmBiometryVerification(verificationId: String, faceScan: String, auditTrailImage: String, lowQualityAuditTrailImage: String)

    struct ConfirmGuardianRequest: Codable {
        var participantId: ParticipantId
        var keyConfirmationSignature: String
        var keyConfirmationTimeMillis: Int64
    }
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
        case .createGuardian:
            return "v1/guardians"
        case .deleteGuardian(let id):
            return "v1/guardians/\(id)"
        case .inviteGuardian(let id):
            return "v1/guardians/\(id)/invite"
        case .confirmGuardian(let request):
            return "v1/guardians/\(request.participantId)/confirm"
        case .registerPushToken:
            return "v1/notification-tokens"
        case .initBiometryVerification:
            return "/v1/biometry-verifications"
        case .confirmBiometryVerification(let verificationId, _, _, _):
            return "v1/biometry-verifications/\(verificationId)/biometry"
        }
    }

    var method: Moya.Method {
        switch self {
        case .minVersion,
             .user:
            return .get
        case .createUser,
             .contactVerification,
             .registerPushToken,
             .createPolicy,
             .createGuardian,
             .confirmGuardian,
             .inviteGuardian,
             .initBiometryVerification,
             .confirmBiometryVerification:
            return .post
        case .deleteGuardian:
            return .delete
        }
    }

    var task: Moya.Task {
        switch self {
        case .minVersion,
             .user,
             .initBiometryVerification,
             .inviteGuardian,
             .deleteGuardian:
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
        case .createPolicy(let request):
            return .requestJSONEncodable(request)

        case .confirmBiometryVerification(_, let faceScan, let auditTrailImage, let lowQualityAuditTrailImage):
            return .requestJSONEncodable(
                ConfirmBiometryVerificationApiRequest(faceScan: faceScan, auditTrailImage: auditTrailImage, lowQualityAuditTrailImage: lowQualityAuditTrailImage)
            )
        case .createGuardian(name: let name):
            return .requestJSONEncodable(
                ["name": name]
            )
        case .confirmGuardian(let request):
            return .requestJSONEncodable(request)
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
