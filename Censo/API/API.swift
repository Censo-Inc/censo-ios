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
        case health
        
        case attestationChallenge
        case registerAttestationObject(challenge: String, attestation: String, keyId: String)
        case attestationKey

        case user
        case deleteUser
        case signIn(UserCredentials)
        case registerPushToken(String)

        case confirmApprover(ConfirmApproverApiRequest)
        case rejectApproverVerification(ParticipantId)

        case createPolicy(CreatePolicyApiRequest)
        case createPolicyWithPassword(CreatePolicyWithPasswordApiRequest)
        case setupPolicy(SetupPolicyApiRequest)
        case deletePolicySetup
        case replacePolicy(ReplacePolicyApiRequest)

        case initBiometryVerification
        case confirmBiometryVerification(verificationId: String, faceScan: String, auditTrailImage: String, lowQualityAuditTrailImage: String)
        
        case unlock(UnlockApiRequest)
        case unlockWithPassword(UnlockWithPasswordApiRequest)
        case prolongUnlock
        case lock
        
        case storeSeedPhrase(StoreSeedPhraseApiRequest)
        case deleteSeedPhrase(guid: String)
        
        case requestAccess(RequestAccessApiRequest)
        case deleteAccess
        case submitAccessTotpVerification(participantId: ParticipantId, payload: SubmitAccessTotpVerificationApiRequest)
        case retrieveAccessShards(RetrieveAccessShardsApiRequest)
        case retrieveAccessShardsWithPassword(RetrieveAccessShardsWithPasswordApiRequest)
        case submitPurchase(SubmitPurchaseApiRequest)

        case acceptImport(channel: String, ownerProof: OwnerProof)
        case getImportEncryptedData(channel: String)
        
        case enableTimelock
        case disableTimelock
        case cancelDisabledTimelock
    }
}

extension API: TargetType {
    var baseURL: URL {
        Configuration.apiBaseURL
    }

    var path: String {
        switch endpoint {
        case .health:
            return "/health"
        case .attestationChallenge:
            return "v1/attestation-challenge"
        case .registerAttestationObject:
            return "v1/apple-attestation"
        case .attestationKey:
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
        case .deletePolicySetup:
            return "v1/policy-setup"
        case .replacePolicy:
            return "v1/policy"
        case .confirmApprover(let request):
            return "v1/approvers/\(request.participantId.value)/confirmation"
        case .rejectApproverVerification(let id):
            return "v1/approvers/\(id.value)/verification/reject"
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
        case .storeSeedPhrase:
            return "v1/vault/seed-phrases"
        case .deleteSeedPhrase(let guid):
            return "v1/vault/seed-phrases/\(guid)"
        case .requestAccess:
            return "v1/access"
        case .deleteAccess:
            return "v1/access"
        case .submitAccessTotpVerification(let participantId, _):
            return "v1/access/\(participantId.value)/totp-verification"
        case .retrieveAccessShards:
            return "v1/access/retrieval"
        case .retrieveAccessShardsWithPassword:
            return "v1/access/retrieval-password"
        case .submitPurchase:
            return "v1/purchases"
        case .acceptImport(let channel, _):
            return "v1/import/\(channel)/accept"
        case .getImportEncryptedData(let channel):
            return "v1/import/\(channel)/encrypted"
        case .enableTimelock:
            return "v1/timelock/enable"
        case .disableTimelock,
             .cancelDisabledTimelock:
            return "v1/timelock/disable"
        }
    }

    var method: Moya.Method {
        switch endpoint {
        case .health,
             .user,
             .attestationKey,
             .getImportEncryptedData:
            return .get
        case .deleteUser, .deleteSeedPhrase, .deleteAccess, .deletePolicySetup, .cancelDisabledTimelock:
            return .delete
        case .signIn,
             .registerPushToken,
             .createPolicy,
             .createPolicyWithPassword,
             .setupPolicy,
             .confirmApprover,
             .rejectApproverVerification,
             .initBiometryVerification,
             .confirmBiometryVerification,
             .unlock,
             .unlockWithPassword,
             .prolongUnlock,
             .lock,
             .storeSeedPhrase,
             .requestAccess,
             .submitAccessTotpVerification,
             .retrieveAccessShards,
             .retrieveAccessShardsWithPassword,
             .registerAttestationObject,
             .attestationChallenge,
             .submitPurchase,
             .acceptImport,
             .enableTimelock,
             .disableTimelock:
            return .post
        case .replacePolicy:
            return .put
        }
    }

    var task: Moya.Task {
        switch endpoint {
        case .health,
             .user,
             .deleteUser,
             .initBiometryVerification,
             .rejectApproverVerification,
             .attestationChallenge,
             .attestationKey,
             .getImportEncryptedData,
             .deletePolicySetup,
             .enableTimelock,
             .disableTimelock,
             .cancelDisabledTimelock:
            return .requestPlain
        case .signIn(let credentials):
            return .requestJSONEncodable([
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
        case .confirmApprover(let request):
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
        case .storeSeedPhrase(let request):
            return .requestJSONEncodable(request)
        case .deleteSeedPhrase:
            return .requestPlain
        case .requestAccess(let request):
            return .requestJSONEncodable(request)
        case .deleteAccess:
            return .requestPlain
        case .submitAccessTotpVerification(_, let payload):
            return .requestJSONEncodable(payload)
        case .retrieveAccessShards(let request):
            return .requestJSONEncodable(request)
        case .retrieveAccessShardsWithPassword(let request):
            return .requestJSONEncodable(request)
        case .submitPurchase(let request):
            return .requestJSONEncodable(request)
        case .acceptImport(_, let ownerProof):
            return .requestJSONEncodable(ownerProof)
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
        case .health,
             .user,
             .attestationChallenge,
             .registerAttestationObject,
             .registerPushToken,
             .rejectApproverVerification,
             .setupPolicy,
             .initBiometryVerification,
             .confirmBiometryVerification,
             .unlock,
             .unlockWithPassword,
             .prolongUnlock,
             .lock,
             .storeSeedPhrase,
             .deleteAccess,
             .attestationKey,
             .getImportEncryptedData,
             .enableTimelock,
             .disableTimelock,
             .cancelDisabledTimelock:
            return false
        case .signIn,
             .deleteUser,
             .createPolicy,
             .createPolicyWithPassword,
             .replacePolicy,
             .requestAccess,
             .submitAccessTotpVerification,
             .retrieveAccessShards,
             .retrieveAccessShardsWithPassword,
             .deleteSeedPhrase,
             .confirmApprover,
             .submitPurchase,
             .acceptImport,
             .deletePolicySetup:
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
