//
//  ParticipantId+PrivateKeyStorage.swift
//  Guardian
//
//  Created by Brendan Flood on 10/3/23.
//

import Foundation

extension ParticipantId {
    func persistEncodedPrivateKey(encodedPrivateKey: String) {
        NSUbiquitousKeyValueStore.default.set(encodedPrivateKey, forKey: self.value)
    }
    
    var privateKey: EncryptionKey? {
        guard let x963KeyData = NSUbiquitousKeyValueStore.default.string(forKey: self.value)?.hexData(),
              let encryptionKey = try? EncryptionKey.generateFromPrivateKeyX963(data: x963KeyData) else {
            return nil
        }
        return encryptionKey
    }
}

func generateEncodedPrivateKey() -> String? {
    return try? EncryptionKey.generateRandomKey().privateKeyX963().toHexString()
}
