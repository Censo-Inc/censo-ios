//
//  ParticipantId+PrivateKeyStorage.swift
//  Guardian
//
//  Created by Brendan Flood on 10/3/23.
//

import Foundation
import CryptoKit

extension ParticipantId {
    func persistEncodedPrivateKey(encodedPrivateKey: String) {
        NSUbiquitousKeyValueStore.default.set(encodedPrivateKey, forKey: self.value)
    }
    
    func privateKey(userIdentifier: String) -> EncryptionKey? {
        let symmetricKey = SymmetricKey(data: SHA256.hash(data: userIdentifier.data(using: .utf8)!))

        guard let encryptedKey = NSUbiquitousKeyValueStore.default.string(forKey: self.value)?.hexData(),
              let x963KeyData = symmetricDecryption(ciphertext: encryptedKey, key: symmetricKey),
              let encryptionKey = try? EncryptionKey.generateFromPrivateKeyX963(data: x963KeyData) else {
            return nil
        }
        return encryptionKey
    }
}

func generateEncryptedPrivateKey(userIdentifier: String) -> String? {
    return try? symmetricEncryption(
        message: EncryptionKey.generateRandomKey().privateKeyX963(),
        key: SymmetricKey(data: SHA256.hash(data: userIdentifier.data(using: .utf8)!))
    ).toHexString()
}
