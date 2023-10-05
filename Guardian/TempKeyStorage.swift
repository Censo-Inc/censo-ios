//
//  TempKeyStorage.swift
//  Guardian
//
//  Created by Brendan Flood on 10/3/23.
//

import Foundation

extension ParticipantId {
    
    func generateGuardianKey() throws -> EncryptionKey {
        let defaults = UserDefaults.standard
        if let x963KeyData = defaults.string(forKey: self.value)?.hexData() {
            return try EncryptionKey.generateFromPrivateKeyX963(data: x963KeyData)
        }
        let encryptionKey = try EncryptionKey.generateRandomKey()
        defaults.set((try? encryptionKey.privateKeyX963())?.toHexString(), forKey: self.value)
        return encryptionKey
    }
    
    var privateKey: EncryptionKey? {
        let defaults = UserDefaults.standard
        guard let x963KeyData = defaults.string(forKey: self.value)?.hexData(),
              let encryptionKey = try? EncryptionKey.generateFromPrivateKeyX963(data: x963KeyData) else {
            return nil
        }
        return encryptionKey
    }
}
