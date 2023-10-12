//
//  SymmetricEncryption.swift
//  Vault
//
//  Created by Ben Holzman on 10/12/23.
//

import CryptoKit
import Foundation


private func randomData(count: Int) -> Data {
    return Data((0..<count).map { _ in UInt8.random(in: .min ... .max) })
}

func symmetricEncryption(message: Data, key: SymmetricKey) -> Data {
    do {
        let nonce = try AES.GCM.Nonce(data: randomData(count: 12))
        let sealedBox = try AES.GCM.seal(message, using: key, nonce: nonce)
        return sealedBox.combined!
    } catch {
        fatalError("Encryption failed: \(error.localizedDescription)")
    }
}

func symmetricDecryption(ciphertext: Data, key: SymmetricKey) -> Data? {
    do {
        let sealedBox = try AES.GCM.SealedBox(combined: ciphertext)
        let decrypted = try AES.GCM.open(sealedBox, using: key)
        return Data(decrypted)
    } catch {
        fatalError("Decryption failed: \(error.localizedDescription)")
    }
}
