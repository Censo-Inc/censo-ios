//
//  ParticipantId+PrivateKeyStorage.swift
//  Approver
//
//  Created by Brendan Flood on 10/3/23.
//

import Foundation
import CryptoKit
import SwiftKeccak
import raygun4apple

enum KeyMigration: Swift.Error {
    case migrationStarted
    case migrationFailed
    case migrationCompleted
}

extension ParticipantId {
    func persistEncodedPrivateKey(encodedPrivateKey: String) {
        NSUbiquitousKeyValueStore.default.set("|v2|\(encodedPrivateKey)", forKey: self.value)
    }
    
    func deleteEncodedPrivateKey() {
        NSUbiquitousKeyValueStore.default.removeObject(forKey: self.value)
    }
    
    func privateKey(userIdentifier: String) -> EncryptionKey? {
        guard let encryptedKey = NSUbiquitousKeyValueStore.default.string(forKey: self.value) else {
            return nil
        }
        let symmetricKey = SymmetricKey(data: keccak256(userIdentifier))
        if (encryptedKey.starts(with: "|v2|")) {
            guard let encryptedKeyData = String(encryptedKey.dropFirst(4)).hexData(),
                  let x963KeyData = try? symmetricKey.decrypt(ciphertext: encryptedKeyData) else {
                return nil
            }
            return try? EncryptionKey.generateFromPrivateKeyX963(data: x963KeyData)
        } else {
            RaygunClient.sharedInstance().send(error: KeyMigration.migrationStarted, tags: ["Key Migration"], customData: nil)

            let oldSymmetricKey = SymmetricKey(data: SHA256.hash(data: userIdentifier.data(using: .utf8)!))
            guard let encryptedKeyData = encryptedKey.hexData(),
                  let oldX963KeyData = try? oldSymmetricKey.decrypt(ciphertext: encryptedKeyData),
                  let newEncryptedData = try? symmetricKey.encrypt(message: oldX963KeyData) else {
                RaygunClient.sharedInstance().send(error: KeyMigration.migrationFailed, tags: ["Key Migration"], customData: nil)
                return nil
            }
            persistEncodedPrivateKey(encodedPrivateKey: newEncryptedData.toHexString())
            RaygunClient.sharedInstance().send(error: KeyMigration.migrationCompleted, tags: ["Key Migration"], customData: nil)
            return try? EncryptionKey.generateFromPrivateKeyX963(data: oldX963KeyData)
        }
    }
}

func generatePrivateKey() throws -> Data {
    return try EncryptionKey.generateRandomKey().privateKeyX963()
}

func encryptPrivateKey(privateKey: Data, userIdentifier: String) -> String? {
    return try? SymmetricKey(
        data: keccak256(userIdentifier)
    ).encrypt(message: privateKey).toHexString()
}

