//
//  Session.swift
//  Censo
//
//  Created by Ata Namvari on 2023-09-19.
//

import Foundation
import Sentry

struct Session : Equatable {
    var deviceKey: DeviceKey
    var userCredentials: UserCredentials
}

extension Session {
    func getOrCreateApproverKey(participantId: ParticipantId, entropy: Data) throws -> EncryptionKey {
        let userIdentifier = self.userCredentials.userIdentifier
        let existingKey = participantId.privateKey(userIdentifier: userIdentifier, entropy: entropy)
        if (existingKey == nil) {
            let encryptionKey = try generateApproverKey(participantId: participantId)
            try persistApproverKey(participantId: participantId, key: encryptionKey, entropy: entropy)
            return encryptionKey
        } else {
            return existingKey!
        }
    }
    
    func generateApproverKey(participantId: ParticipantId) throws -> EncryptionKey {
        guard let privateKey = try? generatePrivateKey() else {
            SentrySDK.captureWithTag(error: CensoError.failedToCreateApproverKey, tagValue: "Approver Key")
            throw CensoError.failedToCreateApproverKey
        }
        
        return try EncryptionKey.generateFromPrivateKeyX963(data: privateKey)
    }
    
    func persistApproverKey(participantId: ParticipantId, key: EncryptionKey, entropy: Data?) throws {
        let userIdentifier = self.userCredentials.userIdentifier
        guard let encryptedKey = encryptPrivateKey(privateKey: try key.privateKeyX963(), userIdentifier: userIdentifier, entropy: entropy) else {
            SentrySDK.captureWithTag(error: CensoError.failedToPersistApproverKey, tagValue: "Approver Key")
            throw CensoError.failedToPersistApproverKey
        }
        participantId.persistEncodedPrivateKey(encodedPrivateKey: encryptedKey, entropy: entropy)
    }
    
    func approverKeyExists(participantId: ParticipantId, entropy: Data) -> Bool {
        let userIdentifier = self.userCredentials.userIdentifier
        return participantId.privateKey(userIdentifier: userIdentifier, entropy: entropy) != nil
    }
    
    func deleteApproverKey(participantId: ParticipantId) {
        participantId.deleteEncodedPrivateKey()
    }
    
    func deleteDeviceKey() {
        SecureEnclaveWrapper.removeDeviceKey(for: userCredentials.userIdentifier)
    }
}
