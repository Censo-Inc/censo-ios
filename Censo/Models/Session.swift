//
//  Session.swift
//  Censo
//
//  Created by Ata Namvari on 2023-09-19.
//

import Foundation
import Sentry

struct Session {
    var deviceKey: DeviceKey
    var userCredentials: UserCredentials
}

extension Session {
    func getOrCreateApproverKey(participantId: ParticipantId, entropy: Data?) throws -> EncryptionKey {
        let userIdentifier = self.userCredentials.userIdentifier
        let existingKey = participantId.privateKey(userIdentifier: userIdentifier, entropy: entropy)
        if (existingKey == nil) {
            guard let privateKey = try? generatePrivateKey(),
                  let encryptedKey = encryptPrivateKey(privateKey: privateKey, userIdentifier: userIdentifier, entropy: entropy) else {
                SentrySDK.captureWithTag(error: CensoError.failedToCreateApproverKey, tagValue: "Approver Key")
                throw CensoError.failedToCreateApproverKey
            }
            participantId.persistEncodedPrivateKey(encodedPrivateKey: encryptedKey, entropy: entropy)
            return try EncryptionKey.generateFromPrivateKeyX963(data: privateKey)
        } else {
            return existingKey!
        }
    }
    
    func deleteApproverKey(participantId: ParticipantId) {
        participantId.deleteEncodedPrivateKey()
    }
    
    func deleteDeviceKey() {
        SecureEnclaveWrapper.removeDeviceKey(for: userCredentials.userIdentifier)
    }
}
