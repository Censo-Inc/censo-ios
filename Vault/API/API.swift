//
//  API.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-15.
//

import Foundation
import Moya
import UIKit

struct API {
    var deviceKey: DeviceKey
    var endpoint: Endpoint

    enum Endpoint {
        case user
        case signIn(UserCredentials)
        case registerPushToken(String)

        case createGuardian(name: String)
        case deleteGuardian(ParticipantId)
        case inviteGuardian(InviteGuardianApiRequest)
        case confirmGuardian(ConfirmGuardianApiRequest)
        case rejectGuardianVerification(ParticipantId)

        case createPolicy(CreatePolicyApiRequest)

        case initBiometryVerification
        case confirmBiometryVerification(verificationId: String, faceScan: String, auditTrailImage: String, lowQualityAuditTrailImage: String)
        
        case unlock(UnlockApiRequest)
        case lock
    }

    struct ConfirmGuardianRequest: Codable {
        var participantId: ParticipantId
        var keyConfirmationSignature: String
        var keyConfirmationTimeMillis: Int64
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
        case .createPolicy:
            return "v1/policies"
        case .createGuardian:
            return "v1/guardians"
        case .deleteGuardian(let id):
            return "v1/guardians/\(id.value)"
        case .inviteGuardian(let request):
            return "v1/guardians/\(request.participantId.value)/invitation"
        case .confirmGuardian(let request):
            return "v1/guardians/\(request.participantId.value)/confirmation"
        case .rejectGuardianVerification(let id):
            return "v1/guardians/\(id.value)/verification/reject"
        case .registerPushToken:
            return "v1/notification-tokens"
        case .initBiometryVerification:
            return "/v1/biometry-verifications"
        case .confirmBiometryVerification(let verificationId, _, _, _):
            return "v1/biometry-verifications/\(verificationId)/biometry"
        case .unlock:
            return "v1/unlock"
        case .lock:
            return "v1/lock"
        }
    }

    var method: Moya.Method {
        switch endpoint {
        case .user:
            return .get
        case .deleteGuardian:
            return .delete
        case .signIn,
             .registerPushToken,
             .createPolicy,
             .createGuardian,
             .confirmGuardian,
             .rejectGuardianVerification,
             .inviteGuardian,
             .initBiometryVerification,
             .confirmBiometryVerification,
             .unlock,
             .lock:
            return .post
        }
    }

    var task: Moya.Task {
        switch endpoint {
        case .user,
             .initBiometryVerification,
             .rejectGuardianVerification,
             .deleteGuardian:
            return .requestPlain
        case .signIn(let credentials):
            return .requestJSONEncodable(credentials)
        case .registerPushToken(let token):
            return .requestJSONEncodable([
                "token": token,
                "deviceType": "Ios"
            ])
        case .createPolicy(let request):
            return .requestJSONEncodable(request)

        case .confirmGuardian(let request):
            return .requestJSONEncodable(request)
            
        case .confirmBiometryVerification(_, let faceScan, let auditTrailImage, let lowQualityAuditTrailImage):
            return .requestJSONEncodable(
                ConfirmBiometryVerificationApiRequest(faceScan: faceScan, auditTrailImage: auditTrailImage, lowQualityAuditTrailImage: lowQualityAuditTrailImage)
            )
        case .createGuardian(name: let name):
            return .requestJSONEncodable(
                ["name": name]
            )
            
        case .inviteGuardian(let request):
            return .requestJSONEncodable(request)
            
        case .unlock(let request):
            return .requestJSONEncodable(request)
        case .lock:
            return .requestPlain
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
