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
        case deleteUser
        case signIn(UserCredentials)
        case registerPushToken(String)

        case confirmGuardian(ConfirmGuardianApiRequest)
        case rejectGuardianVerification(ParticipantId)

        case createPolicy(CreatePolicyApiRequest)
        case setupPolicy(SetupPolicyApiRequest)
        case replacePolicy(ReplacePolicyApiRequest)

        case initBiometryVerification
        case confirmBiometryVerification(verificationId: String, faceScan: String, auditTrailImage: String, lowQualityAuditTrailImage: String)
        
        case unlock(UnlockApiRequest)
        case prolongUnlock
        case lock
        
        case storeSecret(StoreSecretApiRequest)
        case deleteSecret(guid: String)
        
        case requestRecovery(RequestRecoveryApiRequest)
        case deleteRecovery
        case submitRecoveryTotpVerification(participantId: ParticipantId, payload: SubmitRecoveryTotpVerificationApiRequest)
        case retrieveRecoveredShards(RetrieveRecoveryShardsApiRequest)
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
        case .user,
             .deleteUser:
            return "v1/user"
        case .createPolicy:
            return "v1/policy"
        case .setupPolicy:
            return "v1/policy-setup"
        case .replacePolicy:
            return "v1/policy"
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
        case .prolongUnlock:
            return "v1/unlock-prolongation"
        case .lock:
            return "v1/lock"
        case .storeSecret:
            return "v1/vault/secrets"
        case .deleteSecret(let guid):
            return "v1/vault/secrets/\(guid)"
        case .requestRecovery:
            return "v1/recovery"
        case .deleteRecovery:
            return "v1/recovery"
        case .submitRecoveryTotpVerification(let participantId, _):
            return "v1/recovery/\(participantId.value)/totp-verification"
        case .retrieveRecoveredShards:
            return "v1/recovery/retrieval"
        }
    }

    var method: Moya.Method {
        switch endpoint {
        case .user:
            return .get
        case .deleteUser, .deleteSecret, .deleteRecovery:
            return .delete
        case .signIn,
             .registerPushToken,
             .createPolicy,
             .setupPolicy,
             .confirmGuardian,
             .rejectGuardianVerification,
             .initBiometryVerification,
             .confirmBiometryVerification,
             .unlock,
             .prolongUnlock,
             .lock,
             .storeSecret,
             .requestRecovery,
             .submitRecoveryTotpVerification,
             .retrieveRecoveredShards:
            return .post
        case .replacePolicy:
            return .put
        }
    }

    var task: Moya.Task {
        switch endpoint {
        case .user,
             .deleteUser,
             .initBiometryVerification,
             .rejectGuardianVerification:
            return .requestPlain
        case .signIn(let credentials):
            return .requestJSONEncodable(credentials)
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
        case .createPolicy(let request):
            return .requestJSONEncodable(request)
        case .setupPolicy(let request):
            return .requestJSONEncodable(request)
        case .replacePolicy(let request):
            return .requestJSONEncodable(request)
        case .confirmGuardian(let request):
            return .requestJSONEncodable(request)
        case .confirmBiometryVerification(_, let faceScan, let auditTrailImage, let lowQualityAuditTrailImage):
            return .requestJSONEncodable(
                ConfirmBiometryVerificationApiRequest(faceScan: faceScan, auditTrailImage: auditTrailImage, lowQualityAuditTrailImage: lowQualityAuditTrailImage)
            )
        case .unlock(let request):
            return .requestJSONEncodable(request)
        case .prolongUnlock:
            return .requestPlain
        case .lock:
            return .requestPlain
        case .storeSecret(let request):
            return .requestJSONEncodable(request)
        case .deleteSecret:
            return .requestPlain
        case .requestRecovery(let request):
            return .requestJSONEncodable(request)
        case .deleteRecovery:
            return .requestPlain
        case .submitRecoveryTotpVerification(_, let payload):
            return .requestJSONEncodable(payload)
        case .retrieveRecoveredShards(let request):
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
