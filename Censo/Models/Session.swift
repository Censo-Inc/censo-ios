//
//  Session.swift
//  Censo
//
//  Created by Ata Namvari on 2023-09-19.
//

import Foundation
import Sentry

final class Session : ObservableObject {
    private(set) var deviceKey: DeviceKey
    private(set) var userCredentials: UserCredentials
    
    init(deviceKey: DeviceKey, userCredentials: UserCredentials) {
        self.deviceKey = deviceKey
        self.userCredentials = userCredentials
    }
    
    func getOrCreateApproverKey(keyId: KeyId, entropy: Data) throws -> EncryptionKey {
        let userIdentifier = self.userCredentials.userIdentifier
        let existingKey = keyId.privateKey(userIdentifier: userIdentifier, entropy: entropy)
        if (existingKey == nil) {
            let encryptionKey = try generateApproverKey()
            try persistApproverKey(keyId: keyId, key: encryptionKey, entropy: entropy)
            return encryptionKey
        } else {
            return existingKey!
        }
    }
    
    func generateApproverKey() throws -> EncryptionKey {
        guard let privateKey = try? generatePrivateKey() else {
            SentrySDK.captureWithTag(error: CensoError.failedToCreateApproverKey, tagValue: "Approver Key")
            throw CensoError.failedToCreateApproverKey
        }
        
        return try EncryptionKey.generateFromPrivateKeyX963(data: privateKey)
    }
    
    func persistApproverKey(keyId: KeyId, key: EncryptionKey, entropy: Data?) throws {
        let userIdentifier = self.userCredentials.userIdentifier
        guard let encryptedKey = encryptPrivateKey(privateKey: try key.privateKeyX963(), userIdentifier: userIdentifier, entropy: entropy) else {
            SentrySDK.captureWithTag(error: CensoError.failedToPersistApproverKey, tagValue: "Approver Key")
            throw CensoError.failedToPersistApproverKey
        }
        keyId.persistEncodedPrivateKey(encodedPrivateKey: encryptedKey, entropy: entropy)
    }
    
    func approverKeyExists(keyId: KeyId, entropy: Data) -> Bool {
        let userIdentifier = self.userCredentials.userIdentifier
        return keyId.privateKey(userIdentifier: userIdentifier, entropy: entropy) != nil
    }
    
    func deleteApproverKey(keyId: KeyId) {
        keyId.deleteEncodedPrivateKey()
    }
    
    func deleteDeviceKey() {
        SecureEnclaveWrapper.removeDeviceKey(for: userCredentials.userIdentifier)
    }
}
