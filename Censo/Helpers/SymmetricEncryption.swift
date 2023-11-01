//
//  SymmetricEncryption.swift
//  Censo
//
//  Created by Ben Holzman on 10/12/23.
//

import CryptoKit
import Foundation

extension SymmetricKey {
    
    private func randomData(count: Int) -> Data {
        return Data((0..<count).map { _ in UInt8.random(in: .min ... .max) })
    }
    
    func encrypt(message: Data) throws -> Data {
        do {
            let nonce = try AES.GCM.Nonce(data: randomData(count: 12))
            let sealedBox = try AES.GCM.seal(message, using: self, nonce: nonce)
            return sealedBox.combined!
        } catch {
            throw error
        }
    }
    
    func decrypt(ciphertext: Data) throws -> Data? {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: ciphertext)
            let decrypted = try AES.GCM.open(sealedBox, using: self)
            return Data(decrypted)
        } catch {
            throw error
        }
    }

}
