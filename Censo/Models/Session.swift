//
//  Session.swift
//  Censo
//
//  Created by Ata Namvari on 2023-09-19.
//

import Foundation
import raygun4apple

struct Session {
    var deviceKey: DeviceKey
    var userCredentials: UserCredentials
}

extension Session {
    func getOrCreateApproverKey(participantId: ParticipantId) throws -> EncryptionKey {
        let userIdentifier = self.userCredentials.userIdentifier
        let existingKey = participantId.privateKey(userIdentifier: userIdentifier)
        if (existingKey == nil) {
            guard let privateKey = try? generatePrivateKey(),
                  let encryptedKey = encryptPrivateKey(privateKey: privateKey, userIdentifier: userIdentifier) else {
                RaygunClient.sharedInstance().send(error: CensoError.failedToCreateApproverKey, tags: ["Approver Key"], customData: nil)
                throw CensoError.failedToCreateApproverKey
            }
            participantId.persistEncodedPrivateKey(encodedPrivateKey: encryptedKey)
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
