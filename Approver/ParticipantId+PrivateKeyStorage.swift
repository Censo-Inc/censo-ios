//
//  ParticipantId+PrivateKeyStorage.swift
//  Approver
//
//  Created by Brendan Flood on 10/3/23.
//

import Foundation
import CryptoKit
import SwiftKeccak
import Sentry

enum KeyMigration: Swift.Error {
    case migrationStarted
    case migrationFailed
    case migrationCompleted
}

extension ParticipantId {
    func persistEncodedPrivateKey(encodedPrivateKey: String, entropy: Data?) {
        if (entropy == nil) {
            NSUbiquitousKeyValueStore.default.set("|v2|\(encodedPrivateKey)", forKey: self.value)
        } else {
            NSUbiquitousKeyValueStore.default.set("|v3|\(encodedPrivateKey)", forKey: self.value)
        }
    }
    
    func deleteEncodedPrivateKey() {
        NSUbiquitousKeyValueStore.default.removeObject(forKey: self.value)
    }
    
    func privateKey(userIdentifier: String, entropy: Data) -> EncryptionKey? {
        guard let encryptedKey = NSUbiquitousKeyValueStore.default.string(forKey: self.value) else {
            return nil
        }
        if (encryptedKey.starts(with: "|v3|")) {
            let symmetricKey = SymmetricKey(data: keccak256(keccak256(userIdentifier) + entropy))

            guard let encryptedKeyData = String(encryptedKey.dropFirst(4)).hexData(),
                  let x963KeyData = try? symmetricKey.decrypt(ciphertext: encryptedKeyData) else {
                return nil
            }
            return try? EncryptionKey.generateFromPrivateKeyX963(data: x963KeyData)
        } else if (encryptedKey.starts(with: "|v2|")) {
            let symmetricKey = SymmetricKey(data: keccak256(keccak256(userIdentifier) + entropy))

            SentrySDK.captureWithTag(error: KeyMigration.migrationStarted, tagValue: "Key Migration v2->v3")
            
            let oldSymmetricKey = SymmetricKey(data: keccak256(userIdentifier))
            guard let encryptedKeyData = String(encryptedKey.dropFirst(4)).hexData(),
                  let oldX963KeyData = try? oldSymmetricKey.decrypt(ciphertext: encryptedKeyData),
                  let newEncryptedData = try? symmetricKey.encrypt(message: oldX963KeyData) else {
                SentrySDK.captureWithTag(error: KeyMigration.migrationFailed, tagValue: "Key Migration v2->v3")
                return nil
            }
            persistEncodedPrivateKey(encodedPrivateKey: newEncryptedData.toHexString(), entropy: entropy)
            SentrySDK.captureWithTag(error: KeyMigration.migrationCompleted, tagValue: "Key Migration v2->v3")
            return try? EncryptionKey.generateFromPrivateKeyX963(data: oldX963KeyData)
        } else {
            let symmetricKey = SymmetricKey(data: keccak256(keccak256(userIdentifier) + entropy))
            
            SentrySDK.captureWithTag(error: KeyMigration.migrationStarted, tagValue: "Key Migration v1->v3")
            
            let oldSymmetricKey = SymmetricKey(data: SHA256.hash(data: userIdentifier.data(using: .utf8)!))
            guard let encryptedKeyData = encryptedKey.hexData(),
                  let oldX963KeyData = try? oldSymmetricKey.decrypt(ciphertext: encryptedKeyData),
                  let newEncryptedData = try? symmetricKey.encrypt(message: oldX963KeyData) else {
                SentrySDK.captureWithTag(error: KeyMigration.migrationFailed, tagValue: "Key Migration v1->v3")
                return nil
            }
            persistEncodedPrivateKey(encodedPrivateKey: newEncryptedData.toHexString(), entropy: entropy)
            SentrySDK.captureWithTag(error: KeyMigration.migrationCompleted, tagValue: "Key Migration")
            return try? EncryptionKey.generateFromPrivateKeyX963(data: oldX963KeyData)
        }
    }
}

func generatePrivateKey() throws -> Data {
    return try EncryptionKey.generateRandomKey().privateKeyX963()
}

func encryptPrivateKey(privateKey: Data, userIdentifier: String, entropy: Data?) -> String? {
    if (entropy == nil) {
        return try? SymmetricKey(
            data: keccak256(userIdentifier)
        ).encrypt(message: privateKey).toHexString()
    } else {
        return try? SymmetricKey(
            data: keccak256(keccak256(userIdentifier) + entropy!)
        ).encrypt(message: privateKey).toHexString()
    }
}

