//
//  EncryptionTests.swift
//  VaultTests
//
//  Created by Ben Holzman on 10/12/23.
//

import XCTest
import CryptoKit

final class EncryptionTests: XCTestCase {
    func testSymmetricEncryption() {
        let message = "Hello, World!"
        let encryptionKey = SymmetricKey(data: SHA256.hash(data: "user-identifier".data(using: .utf8)!))

        let encryptedData = symmetricEncryption(message: message.data(using: .utf8)!, key: encryptionKey)
        print("Encrypted Data: \(encryptedData.base64EncodedString())")

        let decryptedData = symmetricDecryption(ciphertext: encryptedData, key: encryptionKey)
        XCTAssertNotNil(decryptedData)
        let decryptedMessage = String(data: decryptedData!, encoding: .utf8)
        XCTAssertNotNil(decryptedMessage)
        XCTAssertEqual(message, decryptedMessage)
    }
}
