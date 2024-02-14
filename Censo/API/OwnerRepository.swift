//
//  OwnerRepository.swift
//  Censo
//
//  Created by Anton Onyshchenko on 31.01.24.
//

import Foundation
import Moya

final class OwnerRepository : ObservableObject {
    private var apiProvider: MoyaProvider<API>
    private var session: Session
    
    init(_ apiProvider: MoyaProvider<API>, _ session: Session) {
        self.apiProvider = apiProvider
        self.session = session
    }
    
    var deviceKey: DeviceKey {
        get {
            return session.deviceKey
        }
    }
    
    var userIdentifier: String {
        get {
            return session.userCredentials.userIdentifier
        }
    }
    
    var userIdentifierHash: String {
        get {
            return session.userCredentials.userIdentifierHash()
        }
    }
    
    func getOrCreateApproverKey(keyId: KeyId, entropy: Data) throws -> EncryptionKey {
        return try session.getOrCreateApproverKey(keyId: keyId, entropy: entropy)
    }
    
    func generateApproverKey() throws -> EncryptionKey {
        return try session.generateApproverKey()
    }
    
    func persistApproverKey(keyId: KeyId, key: EncryptionKey, entropy: Data?) throws {
        try session.persistApproverKey(keyId: keyId, key: key, entropy: entropy)
    }
    
    func approverKeyExists(keyId: KeyId, entropy: Data) -> Bool {
        return session.approverKeyExists(keyId: keyId, entropy: entropy)
    }
    
    func deleteApproverKey(keyId: KeyId) {
        session.deleteApproverKey(keyId: keyId)
    }
    
    func encryptWithApproverPublicKey(data: Data, policy: API.Policy) throws -> Base64EncodedString {
        guard let ownerEntropy = policy.ownerEntropy else {
            throw CensoError.invalidEntropy
        }
        return try getOrCreateApproverKey(
            keyId: policy.owner!.participantId,
            entropy: ownerEntropy.data
        ).publicExternalRepresentation().toEncryptionKey().encrypt(data: data)
    }
    
    func decryptWithApproverKey(data: Base64EncodedString, policy: API.Policy) throws -> Data {
        guard let ownerEntropy = policy.ownerEntropy else {
            throw CensoError.invalidEntropy
        }
        return try getOrCreateApproverKey(
            keyId: policy.owner!.participantId,
            entropy: ownerEntropy.data
        ).decrypt(base64EncodedString: data)
    }
    
    func decryptStringWithApproverKey(data: Base64EncodedString, policy: API.Policy) throws -> String {
        return String(
            data: try decryptWithApproverKey(data: data, policy: policy),
            encoding: .utf8
        )!
    }
    
    func getUser(_ completion: @escaping (Result<API.User, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .user, completion: completion)
    }
    
    func createDevice(_ completion: @escaping Moya.Completion) {
        apiProvider.request(with: session, endpoint: .createDevice, completion: completion)
    }
    
    func initBiometryVerification(_ completion: @escaping (Result<API.InitBiometryVerificationApiResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .initBiometryVerification, completion: completion) 
    }
    
    func setupPolicy(_ payload: API.SetupPolicyApiRequest, _ completion: @escaping (Result<API.OwnerStateResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .setupPolicy(payload), completion: completion)
    }
    
    func deletePolicySetup(_ completion: @escaping (Result<API.OwnerStateResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .deletePolicySetup, completion: completion)
    }
    
    func confirmApprover(_ payload: API.ConfirmApproverApiRequest, _ completion: @escaping (Result<API.OwnerStateResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .confirmApprover(payload), completion: completion)
    }
    
    func rejectApproverVerification(_ participantId: ParticipantId, _ completion: @escaping (Result<API.OwnerStateResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .rejectApproverVerification(participantId), completion: completion)
    }
    
    func createPolicy(_ payload: API.CreatePolicyApiRequest, _ completion: @escaping (Result<API.AuthEnrollmentApiResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .createPolicy(payload), completion: completion)
    }
    
    func createPassword(_ payload: API.CreatePolicyWithPasswordApiRequest, _ completion: @escaping (Result<API.CreatePolicyWithPasswordApiResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .createPolicyWithPassword(payload), completion: completion)
    }
    
    func lock(_ completion: @escaping (Result<API.LockApiResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .lock, completion: completion)
    }
    
    func unlock(_ payload: API.UnlockApiRequest, _ completion: @escaping (Result<API.UnlockApiResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .unlock(payload), completion: completion)
    }
    
    func prolongUnlock(_ completion: @escaping (Result<API.ProlongUnlockApiResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .prolongUnlock, completion: completion)
    }
    
    func unlockWithPassword(_ payload: API.UnlockWithPasswordApiRequest, _ completion: @escaping (Result<API.UnlockWithPasswordApiResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .unlockWithPassword(payload), completion: completion)
    }
    
    func replaceAuthentication(_ payload: API.ReplaceAuthenticationApiRequest, _ completion: @escaping (Result<API.ReplaceBiometryApiResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .replaceAuthentication(payload), completion: completion)
    }
    
    func retrieveAccessShards(_ payload: API.RetrieveAccessShardsApiRequest, _ completion: @escaping (Result<API.RetrieveAccessShardsApiResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .retrieveAccessShards(payload), completion: completion)
    }
    
    func retrieveAccessShardsWithPassword(_ payload: API.RetrieveAccessShardsWithPasswordApiRequest, _ completion: @escaping (Result<API.RetrieveAccessShardsWithPasswordApiResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .retrieveAccessShardsWithPassword(payload), completion: completion)
    }
    
    func resetLoginId(_ payload: API.ResetLoginIdApiRequest, _ completion: @escaping (Result<API.ResetLoginIdApiResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .resetLoginId(payload), completion: completion)
    }
    
    func resetLoginIdWithPassword(_ payload: API.ResetLoginIdWithPasswordApiRequest, _ completion: @escaping (Result<API.ResetLoginIdWithPasswordApiResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .resetLoginIdWithPassword(payload), completion: completion)
    }
    
    func requestAccess(_ payload: API.RequestAccessApiRequest, _ completion: @escaping (Result<API.RequestAccessApiResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .requestAccess(payload), completion: completion)
    }
    
    func submitAccessTotpVerification(_ participantId: ParticipantId, _ payload: API.SubmitAccessTotpVerificationApiRequest, _ completion: @escaping (Result<API.SubmitAccessTotpVerificationApiResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .submitAccessTotpVerification(participantId: participantId, payload: payload), completion: completion)
    }
    
    func getSeedPhrase(_ guid: String, _ completion: @escaping (Result<API.GetSeedPhraseApiResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .getSeedPhrase(guid: guid), completion: completion)
    }
    
    func deleteAccess(_ completion: @escaping (Result<API.ResetLoginIdWithPasswordApiResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .deleteAccess, completion: completion)
    }
    
    func completeOwnerApprovership(_ payload: API.CompleteOwnerApprovershipApiRequest, _ completion: @escaping Moya.Completion) {
        apiProvider.request(with: session, endpoint: .ownerCompletion(payload), completion: completion)
    }
    
    func replacePolicy(_ payload: API.ReplacePolicyApiRequest, _ completion: @escaping (Result<API.ReplacePolicyApiResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .replacePolicy(payload), completion: completion)
    }
    
    func replacePolicyShards(_ payload: API.ReplacePolicyShardsApiRequest, _ completion: @escaping (Result<API.ReplacePolicyShardsApiResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .replacePolicyShards(payload), completion: completion)
    }
    
    func enableOrDisableTimelock(_ enable: Bool, _ completion: @escaping (Result<API.TimelockApiResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: enable ? .enableTimelock : .disableTimelock, completion: completion)
    }
    
    func cancelDisabledTimelock(_ completion: @escaping Moya.Completion) {
        apiProvider.request(with: session, endpoint: .cancelDisabledTimelock, completion: completion)
    }
    
    func deleteUser(_ completion: @escaping Moya.Completion) {
        apiProvider.request(with: session, endpoint: .deleteUser, completion: completion)
    }
    
    func storeSeedPhrase(_ payload: API.StoreSeedPhraseApiRequest, _ completion: @escaping (Result<API.StoreSeedPhraseApiResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .storeSeedPhrase(payload), completion: completion)
    }
    
    func updateSeedPhraseMetaInfo(guid: String, _ update: API.UpdateSeedPhraseMetaInfoApiRequest.Update, _ completion: @escaping (Result<API.UpdateSeedPhraseMetaInfoApiResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .updateSeedPhraseMetaInfo(guid: guid, payload: API.UpdateSeedPhraseMetaInfoApiRequest(update: update)), completion: completion)
    }
    
    func deleteSeedPhrase(_ guid: String, _ completion: @escaping (Result<API.DeleteSeedPhraseApiResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .deleteSeedPhrase(guid: guid), completion: completion)
    }
    
    func deleteMultipleSeedPhrases(_ guids: [String], _ completion: @escaping (Result<API.DeleteSeedPhraseApiResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .deleteMultipleSeedPhrases(guids: guids), completion: completion)
    }
    
    func requestAuthenticationReset(_ completion: @escaping (Result<API.InitiateAuthenticationResetApiResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .requestAuthenticationReset, completion: completion)
    }
    
    func cancelAuthenticationReset(_ completion: @escaping (Result<API.CancelAuthenticationResetApiResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .cancelAuthenticationReset, completion: completion)
    }
    
    func submitPurchase(_ payload: API.SubmitPurchaseApiRequest, _ completion: @escaping (Result<API.SubmitPurchaseApiResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .submitPurchase(payload), completion: completion)
    }
    
    func getImportEncryptedData(_ channel: String, _ completion: @escaping (Result<GetImportDataByKeyResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .getImportEncryptedData(channel: channel), completion: completion)
    }
    
    func acceptImport(_ channel: String, _ ownerProof: API.OwnerProof, _ completion: @escaping Moya.Completion) {
        apiProvider.request(with: session, endpoint: .acceptImport(channel: channel, ownerProof: ownerProof), completion: completion)
    }
    
    func setPromoCode(_ code: String, _ completion: @escaping Moya.Completion) {
        apiProvider.request(with: session, endpoint: .setPromoCode(code: code), completion: completion)
    }

    func inviteBeneficiary(_ payload: API.InviteBeneficiaryApiRequest, _ completion: @escaping (Result<API.InviteBeneficiaryApiResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .inviteBeneficiary(payload), completion: completion)
    }
    
    func acceptBeneficiaryInvite(_ invitationId: BeneficiaryInvitationId, _ payload: API.AcceptBeneficiaryInvitationApiRequest, _ completion: @escaping (Result<API.AuthEnrollmentApiResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .acceptBeneficiaryInvitation(invitationId, payload), completion: completion)
    }
    
    func acceptBeneficiaryInviteWithPassword(_ invitationId: BeneficiaryInvitationId, _ payload: API.AcceptBeneficiaryInvitationWithPasswordApiRequest, _ completion: @escaping (Result<API.AcceptBeneficiaryInvitationWithPasswordApiResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .acceptBeneficiaryInvitationWithPassword(invitationId, payload), completion: completion)
    }
    
    func activateBeneficiary(_ payload: API.ActivateBeneficiaryApiRequest, _ completion: @escaping (Result<API.ActivateBeneficiaryApiResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .activateBeneficiary(payload), completion: completion)
    }
    
    func rejectBeneficiaryVerification(_ completion: @escaping (Result<API.RejectBeneficiaryVerificationApiResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .rejectBeneficiaryVerification, completion: completion)
    }
    
    func deleteBeneficiary(_ completion: @escaping (Result<API.OwnerStateResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .deleteBeneficiary, completion: completion)
    }
    
    func submitBeneficiaryVerification(_ invitationId: BeneficiaryInvitationId, _ payload: API.SubmitBeneficiaryVerificationApiRequest, _ completion: @escaping (Result<API.SubmitBeneficiaryVerificationApiResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .submitBeneficiaryVerification(invitationId, payload), completion: completion)
    }
    
    func updateApproversContactInfo(_ contactInfos: [API.UpdateBeneficiaryApproverContactInfoApiRequest.ApproverContactInfo], _ completion: @escaping (Result<API.UpdateBeneficiaryApproverContactInfoApiResponse, MoyaError>) -> Void) {
        apiProvider.decodableRequest(with: session, endpoint: .updateApproverContactInfo(API.UpdateBeneficiaryApproverContactInfoApiRequest(approverContacts: contactInfos)), completion: completion)
    }
}
