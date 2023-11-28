//
//  API.swift
//  Censo
//
//  Created by Ata Namvari on 2023-08-15.
//

import Foundation
import Moya
import UIKit
import CryptoKit

struct API {
    var deviceKey: DeviceKey
    var endpoint: Endpoint

    enum Endpoint {
        case attestationChallenge
        case registerAttestationObject(challenge: String, attestation: String, keyId: String)

        case user
        case deleteUser
        case signIn(UserCredentials)
        case registerPushToken(String)

        case confirmGuardian(ConfirmGuardianApiRequest)
        case rejectGuardianVerification(ParticipantId)

        case createPolicy(CreatePolicyApiRequest)
        case createPolicyWithPassword(CreatePolicyWithPasswordApiRequest)
        case setupPolicy(SetupPolicyApiRequest)
        case replacePolicy(ReplacePolicyApiRequest)

        case initBiometryVerification
        case confirmBiometryVerification(verificationId: String, faceScan: String, auditTrailImage: String, lowQualityAuditTrailImage: String)
        
        case unlock(UnlockApiRequest)
        case unlockWithPassword(UnlockWithPasswordApiRequest)
        case prolongUnlock
        case lock
        
        case storeSecret(StoreSecretApiRequest)
        case deleteSecret(guid: String)
        
        case requestRecovery(RequestRecoveryApiRequest)
        case deleteRecovery
        case submitRecoveryTotpVerification(participantId: ParticipantId, payload: SubmitRecoveryTotpVerificationApiRequest)
        case retrieveRecoveredShards(RetrieveRecoveryShardsApiRequest)
        case retrieveRecoveredShardsWithPassword(RetrieveRecoveryShardsWithPasswordApiRequest)
        case submitPurchase(SubmitPurchaseApiRequest)
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
        case .createPolicy:
            return "v1/policy"
        case .createPolicyWithPassword:
            return "v1/policy-password"
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
        case .unlockWithPassword:
            return "v1/unlock-password"
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
        case .retrieveRecoveredShardsWithPassword:
            return "v1/recovery/retrieval-password"
        case .submitPurchase:
            return "v1/purchases"
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
             .createPolicyWithPassword,
             .setupPolicy,
             .confirmGuardian,
             .rejectGuardianVerification,
             .initBiometryVerification,
             .confirmBiometryVerification,
             .unlock,
             .unlockWithPassword,
             .prolongUnlock,
             .lock,
             .storeSecret,
             .requestRecovery,
             .submitRecoveryTotpVerification,
             .retrieveRecoveredShards,
             .retrieveRecoveredShardsWithPassword,
             .registerAttestationObject,
             .attestationChallenge,
             .submitPurchase:
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
             .rejectGuardianVerification,
             .attestationChallenge:
            return .requestPlain
        case .signIn(let credentials):
            return .requestJSONEncodable([
                "jwtToken": "",
                "identityToken": credentials.userIdentifierHash()
            ])
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
        case .createPolicy(let request):
            return .requestJSONEncodable(request)
        case .createPolicyWithPassword(let request):
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
        case .unlockWithPassword(let request):
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
        case .retrieveRecoveredShardsWithPassword(let request):
            return .requestJSONEncodable(request)
        case .submitPurchase(let request):
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
            "X-Censo-App-Identifier": Bundle.main.bundleIdentifier ?? "Unknown",
            "X-Censo-App-Platform": "ios"
        ]
    }

    var requiresAssertion: Bool {
        switch endpoint {
        case .user,
             .attestationChallenge,
             .registerAttestationObject,
             .registerPushToken,
             .rejectGuardianVerification,
             .setupPolicy,
             .initBiometryVerification,
             .confirmBiometryVerification,
             .unlock,
             .unlockWithPassword,
             .prolongUnlock,
             .lock,
             .storeSecret,
             .deleteRecovery:
            return false
        case .signIn,
             .deleteUser,
             .createPolicy,
             .createPolicyWithPassword,
             .replacePolicy,
             .requestRecovery,
             .submitRecoveryTotpVerification,
             .retrieveRecoveredShards,
             .retrieveRecoveredShardsWithPassword,
             .deleteSecret,
             .confirmGuardian,
             .submitPurchase:
            return true
        }
    }
}

extension Data {
    func base58EncodedString() -> String {
        Base58.encode(bytes)
    }
    
    func base58EncodedPublicKey() -> Base58EncodedPublicKey? {
        return try? Base58EncodedPublicKey(data: self)
    }
}

extension Bundle {
    var shortVersionString: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
}
