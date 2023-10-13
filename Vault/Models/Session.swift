//
//  Session.swift
//  Vault
//
//  Created by Ata Namvari on 2023-09-19.
//

import Foundation

struct Session {
    var deviceKey: DeviceKey
    var userCredentials: UserCredentials
}

extension Session {
    func approverKey(participantId: ParticipantId, expectedToExist: Bool = false) throws -> EncryptionKey {
        let userIdentifier = self.userCredentials.userIdentifier
        let existingKey = participantId.privateKey(userIdentifier: userIdentifier)
        if (existingKey == nil && !expectedToExist) {
            guard let privateKey = try? generatePrivateKey(),
                  let encryptedKey = encryptPrivateKey(privateKey: privateKey, userIdentifier: userIdentifier) else {
                throw CensoError.failedToCreateApproverKey
            }
            participantId.persistEncodedPrivateKey(encodedPrivateKey: encryptedKey)
            return try EncryptionKey.generateFromPrivateKeyX963(data: privateKey)
        } else if (existingKey == nil) {
            throw CensoError.failedToRetrieveApproverKey
        } else {
            return existingKey!
        }
    }
}
