//
//  API.swift
//  Approver
//
//  Created by Ata Namvari on 2023-09-13.
//

import Foundation
import Moya
import SwiftUI
import CryptoKit

typealias InvitationId = String
typealias AccessApprovalId = String
typealias AuthenticationResetApprovalId = String
typealias TakeoverId = String

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

        case declineInvitation(InvitationId)
        case acceptInvitation(InvitationId)
        case submitVerification(InvitationId, SubmitApproverVerificationApiRequest)
        
        case storeAccessTotpSecret(AccessApprovalId, Base64EncodedString)
        case approveAccessVerification(AccessApprovalId, Base64EncodedString)
        case rejectAccessVerification(AccessApprovalId)
        
        case labelOwner(ParticipantId, String)
        case createOwnerLoginIdResetToken(ParticipantId)
        
        case acceptAuthenticationResetRequest(AuthenticationResetApprovalId)
        case rejectAuthenticationResetRequest(AuthenticationResetApprovalId)
        case submitAuthenticationResetTotpVerification(AuthenticationResetApprovalId, SubmitAuthenticationResetTotpVerificationApiRequest)
        
        case approveTakeoverInitiation(TakeoverId, ApproveTakeoverInitiationApiRequest)
        case rejectTakeoverInitiation(TakeoverId)
        case storeTakeoverTotpSecret(TakeoverId, Base64EncodedString)
        case approveTakeoverTotpVerification(TakeoverId, Base64EncodedString)
        case rejectTakeoverTotpVerification(TakeoverId)
    }
    
    enum ApproverPhase: Decodable, Equatable {
        case waitingForCode(WaitingForCode)
        case waitingForVerification
        case verificationRejected(VerificationRejected)
        case complete
        case accessRequested(AccessRequested)
        case accessVerification(AccessVerification)
        case accessConfirmation(AccessConfirmation)
        case authenticationResetRequested(AuthenticationResetRequested)
        case authenticationResetWaitingForCode(AuthenticationResetWaitingForCode)
        case authenticationResetVerificationRejected(AuthenticationResetVerificationRejected)
        case takeoverRequested(TakeoverRequested)
        case takeoverVerification(TakeoverVerification)
        case takeoverConfirmation(TakeoverConfirmation)
        
        struct WaitingForCode: Codable, Equatable {
            var entropy: Base64EncodedString
        }

        struct VerificationRejected: Codable, Equatable {
            var entropy: Base64EncodedString
        }
        
        struct AccessRequested: Codable, Equatable {
            var createdAt: Date
            var accessPublicKey: Base58EncodedPublicKey
        }
        
        struct AccessVerification: Codable, Equatable {
            var createdAt: Date
            var accessPublicKey: Base58EncodedPublicKey
            var encryptedTotpSecret: Base64EncodedString
        }
        
        struct AccessConfirmation: Codable, Equatable {
            var createdAt: Date
            var accessPublicKey: Base58EncodedPublicKey
            var encryptedTotpSecret: Base64EncodedString
            var ownerKeySignature: Base64EncodedString
            var ownerKeySignatureTimeMillis: UInt64
            var ownerPublicKey: Base58EncodedPublicKey
            var approverEncryptedShard: Base64EncodedString
            var approverEntropy: Base64EncodedString
        }
        
        struct AuthenticationResetRequested: Codable, Equatable {
            var createdAt: Date
        }
        
        struct AuthenticationResetWaitingForCode: Codable, Equatable {
            var entropy: Base64EncodedString
        }
        
        struct AuthenticationResetVerificationRejected: Codable, Equatable {
            var entropy: Base64EncodedString
        }
        
        struct TakeoverRequested: Codable, Equatable {
            var createdAt: Date
            var entropy: Base64EncodedString
            var timelockPeriodInMillis: UInt64
        }
        
        struct TakeoverVerification: Codable, Equatable {
            var createdAt: Date
            var encryptedTotpSecret: Base64EncodedString
            var unlocksAt: Date?
        }
        
        struct TakeoverConfirmation: Codable, Equatable {
            var createdAt: Date
            var approverKeySignature: Base64EncodedString
            var approverKeySignatureTimeMillis: UInt64
            var timelockPeriodInMillis: UInt64
            var encryptedTotpSecret: Base64EncodedString
            var beneficiaryKeySignature: Base64EncodedString
            var beneficiaryKeySignatureTimeMillis: UInt64
            var beneficiaryPublicKey: Base58EncodedPublicKey
            var approverEncryptedKey: Base64EncodedString
            var entropy: Base64EncodedString
        }
        
        enum ApproverPhaseCodingKeys: String, CodingKey {
            case type
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: ApproverPhaseCodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            switch type {
            case "WaitingForCode":
                self = .waitingForCode(try WaitingForCode(from: decoder))
            case "WaitingForVerification":
                self = .waitingForVerification
            case "VerificationRejected":
                self = .verificationRejected(try VerificationRejected(from: decoder))
            case "Complete":
                self = .complete
            case "AccessRequested":
                self = .accessRequested(try AccessRequested(from: decoder))
            case "AccessVerification":
                self = .accessVerification(try AccessVerification(from: decoder))
            case "AccessConfirmation":
                self = .accessConfirmation(try AccessConfirmation(from: decoder))
            case "AuthenticationResetRequested":
                self = .authenticationResetRequested(try AuthenticationResetRequested(from: decoder))
            case "AuthenticationResetWaitingForCode":
                self = .authenticationResetWaitingForCode(try AuthenticationResetWaitingForCode(from: decoder))
            case "AuthenticationResetVerificationRejected":
                self = .authenticationResetVerificationRejected(try AuthenticationResetVerificationRejected(from: decoder))
            case "TakeoverRequested":
                self = .takeoverRequested(try TakeoverRequested(from: decoder))
            case "TakeoverVerification":
                self = .takeoverVerification(try TakeoverVerification(from: decoder))
            case "TakeoverConfirmation":
                self = .takeoverConfirmation(try TakeoverConfirmation(from: decoder))
            default:
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid ApproverStatus")
            }
        }
        
        var entropy: Base64EncodedString? {
            get {
                return switch self {
                case .waitingForCode(let waitingForCode):
                    waitingForCode.entropy
                case .verificationRejected(let verificationRejected):
                    verificationRejected.entropy
                case .accessConfirmation(let accessConfirmation):
                    accessConfirmation.approverEntropy
                case .waitingForVerification:
                    nil
                case .complete:
                    nil
                case .accessRequested:
                    nil
                case .accessVerification:
                    nil
                case .authenticationResetRequested:
                    nil
                case .authenticationResetWaitingForCode(let waitingForCode):
                    waitingForCode.entropy
                case .authenticationResetVerificationRejected(let rejected):
                    rejected.entropy
                case .takeoverRequested(let takeoverRequested):
                    takeoverRequested.entropy
                case .takeoverVerification:
                    nil
                case .takeoverConfirmation(let takeoverConfirmation):
                    takeoverConfirmation.entropy
                }
            }
        }
    }

    struct ApproverState: Decodable {
        var participantId: ParticipantId
        var phase: ApproverPhase
        var invitationId: String?
        var ownerLabel: String?
        var ownerLoginIdResetToken: OwnerLoginIdResetToken?
    }
    
    struct OwnerLoginIdResetToken: Decodable, Equatable, Hashable {
        var value: String
        var url: URL
        
        init(value: String) throws {
            guard let url = URL(string: "\(Configuration.ownerUrlScheme)://reset/\(value)") else {
                throw ValueWrapperError.invalidResetToken
            }
            self.value = value
            self.url = url
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            do {
                self = try OwnerLoginIdResetToken(value: try container.decode(String.self))
            } catch {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid login id reset token")
            }
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(value)
        }
        
    }
    
    struct ApproverUser: Decodable {
        var approverStates: [ApproverState]
        
        var isActiveApprover: Bool {
            get {
                return approverStates.countActiveApprovers() > 0
            }
        }
    }
    
    struct AcceptInvitationApiResponse: Decodable {
        var approverState: ApproverState
    }
    
    struct SubmitApproverVerificationApiRequest: Encodable {
        var signature: Base64EncodedString
        var timeMillis: UInt64
        var approverPublicKey: Base58EncodedPublicKey
    }
    
    struct SubmitApproverVerificationApiResponse: Decodable {
        var approverState: ApproverState
    }
    
    struct OwnerVerificationApiResponse: Decodable {
        var approverStates: [ApproverState]
    }

    struct AttestationChallenge: Decodable {
        var challenge: Base64EncodedString
    }

    struct AttestationKey: Decodable {
        var keyId: String
    }
    
    struct AcceptAuthenticationResetRequestApiResponse: Decodable {
        var approverStates: [ApproverState]
    }
    
    struct RejectAuthenticationResetRequestApiResponse: Decodable {
        var approverStates: [ApproverState]
    }
    
    struct SubmitAuthenticationResetTotpVerificationApiRequest: Encodable {
        var signature: Base64EncodedString
        var timeMillis: UInt64
    }
    
    struct SubmitAuthenticationResetTotpVerificationApiResponse: Decodable {
        var approverStates: [ApproverState]
    }
    
    struct ApproveTakeoverInitiationApiRequest: Encodable {
        var signature: Base64EncodedString
        var timeMillis: UInt64
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
        case .signIn:
            return "v1/sign-in"
        case .user,
             .deleteUser:
            return "v1/user"
        case .declineInvitation(let id):
            return "v1/approvership-invitations/\(id)/decline"
        case .acceptInvitation(let id):
            return "v1/approvership-invitations/\(id)/accept"
        case .submitVerification(let id, _):
            return "v1/approvership-invitations/\(id)/verification"
        case .storeAccessTotpSecret(let id, _):
            return "v1/access/\(id)/totp"
        case .approveAccessVerification(let id, _):
            return "v1/access/\(id)/approval"
        case .rejectAccessVerification(let id):
            return "v1/access/\(id)/rejection"
        case .attestationKey:
            return "v1/apple-attestation"
        case .labelOwner(let participantId, _):
            return "v1/approvers/\(participantId.value)/owner-label"
        case .createOwnerLoginIdResetToken(let participantId):
            return "v1/login-id-reset-token/\(participantId.value)"
        case .acceptAuthenticationResetRequest(let approvalId):
            return "v1/authentication-reset/\(approvalId)/acceptance"
        case .rejectAuthenticationResetRequest(let approvalId):
            return "v1/authentication-reset/\(approvalId)/rejection"
        case .submitAuthenticationResetTotpVerification(let approvalId, _):
            return "v1/authentication-reset/\(approvalId)/totp-verification"
        case .approveTakeoverInitiation(let takeoverId, _):
            return "v1/takeover/\(takeoverId)/approval"
        case .rejectTakeoverInitiation(let takeoverId):
            return "v1/takeover/\(takeoverId)/rejection"
        case .storeTakeoverTotpSecret(let takeoverId, _):
            return "v1/takeover/\(takeoverId)/totp"
        case .approveTakeoverTotpVerification(let takeoverId, _):
            return "v1/takeover/\(takeoverId)/totp-verification/approval"
        case .rejectTakeoverTotpVerification(let takeoverId):
            return "v1/takeover/\(takeoverId)/totp-verification/rejection"
        }
    }

    var method: Moya.Method {
        switch endpoint {
        case .signIn,
             .declineInvitation,
             .acceptInvitation,
             .submitVerification,
             .storeAccessTotpSecret,
             .approveAccessVerification,
             .rejectAccessVerification,
             .registerAttestationObject,
             .attestationChallenge,
             .createOwnerLoginIdResetToken,
             .acceptAuthenticationResetRequest,
             .rejectAuthenticationResetRequest,
             .submitAuthenticationResetTotpVerification,
             .approveTakeoverInitiation,
             .rejectTakeoverInitiation,
             .storeTakeoverTotpSecret,
             .approveTakeoverTotpVerification,
             .rejectTakeoverTotpVerification:
            return .post
        case .labelOwner:
            return .put
        case .health,
             .user,
             .attestationKey:
            return .get
        case .deleteUser:
            return .delete
        }
    }

    var task: Moya.Task {
        switch endpoint {
        case .health,
             .user,
             .deleteUser,
             .declineInvitation,
             .acceptInvitation,
             .rejectAccessVerification,
             .attestationChallenge,
             .attestationKey,
             .createOwnerLoginIdResetToken,
             .acceptAuthenticationResetRequest,
             .rejectAuthenticationResetRequest,
             .rejectTakeoverInitiation,
             .rejectTakeoverTotpVerification:
            return .requestPlain
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
        case .signIn(let credentials):
            return .requestJSONEncodable([
                "identityToken": credentials.userIdentifierHash()
            ])
        case .submitVerification(_, let request):
            return .requestJSONEncodable(request)
        case .storeAccessTotpSecret(_, let deviceEncryptedTotpSecret):
            return .requestJSONEncodable([
                "deviceEncryptedTotpSecret": deviceEncryptedTotpSecret
            ])
        case .approveAccessVerification(_, let encryptedShard):
            return .requestJSONEncodable([
                "encryptedShard": encryptedShard
            ])
        case .labelOwner(_, let label):
            return .requestJSONEncodable([
                "label": label
            ])
        case .submitAuthenticationResetTotpVerification(_, let request):
            return .requestJSONEncodable(request)
        case .approveTakeoverInitiation(_, let request):
            return .requestJSONEncodable(request)
        case .storeTakeoverTotpSecret(_, let deviceEncryptedTotpSecret):
            return .requestJSONEncodable([
                "deviceEncryptedTotpSecret": deviceEncryptedTotpSecret
            ])
        case .approveTakeoverTotpVerification(_, let encryptedKey):
            return .requestJSONEncodable([
                "encryptedKey": encryptedKey
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
            "X-Censo-App-Identifier": Bundle.main.bundleIdentifier ?? "Unknown",
            "X-Censo-App-Platform": "ios"
        ]
    }

    var requiresAssertion: Bool {
        switch endpoint {
        case .health,
             .user,
             .declineInvitation,
             .acceptInvitation,
             .attestationChallenge,
             .registerAttestationObject,
             .storeAccessTotpSecret,
             .rejectAccessVerification,
             .attestationKey:
            return false
        case .deleteUser,
             .submitVerification,
             .signIn,
             .approveAccessVerification,
             .labelOwner,
             .createOwnerLoginIdResetToken,
             .acceptAuthenticationResetRequest,
             .rejectAuthenticationResetRequest,
             .submitAuthenticationResetTotpVerification,
             .approveTakeoverInitiation,
             .rejectTakeoverInitiation,
             .storeTakeoverTotpSecret,
             .approveTakeoverTotpVerification,
             .rejectTakeoverTotpVerification:
            return true
        }
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
            NetworkLoggerPlugin(configuration: NetworkLoggerPlugin.Configuration(
                formatter: .init(responseData: JSONResponseDataFormatter),
                logOptions: .verbose
            )),
            AuthPlugin(),
            ErrorResponsePlugin(),
            MaintenancePlugin(),
        ]
    )
}

extension EnvironmentValues {
    var apiProvider: MoyaProvider<API> {
        get {
            self[APIProviderEnvironmentKey.self]
        }
        set {
            self[APIProviderEnvironmentKey.self] = newValue
        }
    }
}

extension API.ApproverPhase {
    var isActive: Bool {
        switch self {
        case .complete,
             .accessConfirmation,
             .accessRequested,
             .accessVerification,
             .authenticationResetRequested,
             .authenticationResetWaitingForCode,
             .takeoverRequested,
             .takeoverConfirmation,
             .takeoverVerification:
            return true
        default:
            return false
        }
    }
}

extension Array where Element == API.ApproverState {
    func forInvite(_ invitationId: String) -> API.ApproverState? {
        return self.first(where: {$0.invitationId == invitationId})
    }
    
    func forParticipantId(_ participantId: ParticipantId) -> API.ApproverState? {
        return self.first(where: {$0.participantId == participantId})
    }
    
    func countActiveApprovers() -> Int {
        self.filter({$0.phase.isActive}).count
    }
    
    func hasOther(_ participantId: ParticipantId) -> Bool {
        return self.filter({$0.participantId != participantId}).count > 0
    }
}

struct Owner: Identifiable {
    var id: String {
        get {
            return participantId.value
        }
    }
    
    var label: String?
    var participantId: ParticipantId
}

extension API.ApproverState {
    func toOwner() -> Owner {
        return Owner(label: self.ownerLabel, participantId: self.participantId)
    }
}

