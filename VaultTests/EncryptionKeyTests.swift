//
//  EncryptionKeyTests.swift
//  VaultTests
//
//  Created by Brendan Flood on 9/5/23.
//

import XCTest
import BigInt
@testable import Vault

final class EncryptionKeyTests: XCTestCase {
    
    func testKeyGeneration() throws {
        let privateKey = try EncryptionKey.generateRandomKey()
        let privateKey2 = try EncryptionKey.generateFromPrivateKeyRaw(data: privateKey.privateKeyRaw())
        
        XCTAssertEqual(
            try privateKey.publicExternalRepresentation(),
            try privateKey2.publicExternalRepresentation()
        )
    }
    
    func testSigning() throws {
        let privateKey = try EncryptionKey.generateRandomKey()
        // create a key just from the public so we can verify signature
        let publicKey = try EncryptionKey.generateFromPublicExternalRepresentation(base58PublicKey: privateKey.publicExternalRepresentation())
        let dataToSign = generateRandomHex(lenght: 32).hexData()!
        XCTAssertTrue(
            try publicKey.verifySignature(for: dataToSign, signature: try privateKey.signature(for: dataToSign))
        )
    }
    
    func testEncryptionDecryption() throws {
        let privateKey = try EncryptionKey.generateRandomKey()
        // create a key just from the public so we can encrypt with it
        let publicKey = try EncryptionKey.generateFromPublicExternalRepresentation(base58PublicKey: privateKey.publicExternalRepresentation())
        let dataToEncrypt = generateRandomHex(lenght: 32).hexData()!
        XCTAssertEqual(
            dataToEncrypt.toBase58(),
            try privateKey.decrypt(data: publicKey.encrypt(data: dataToEncrypt)).toBase58()
        )
    }
}
