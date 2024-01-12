//
//  EncryptionTests.swift
//  CensoTests
//
//  Created by Ben Holzman on 10/12/23.
//

import XCTest
import CryptoKit
@testable import Censo

final class EncryptionTests: XCTestCase {
    func testSymmetricEncryption() {
        let message = "Hello, World!"
        let encryptionKey = SymmetricKey(data: SHA256.hash(data: "user-identifier".data(using: .utf8)!))

        let encryptedData = try! encryptionKey.encrypt(message: message.data(using: .utf8)!)
        print("Encrypted Data: \(encryptedData.base64EncodedString())")

        let decryptedData = try? encryptionKey.decrypt(ciphertext: encryptedData)
        XCTAssertNotNil(decryptedData)
        let decryptedMessage = String(data: decryptedData!, encoding: .utf8)
        XCTAssertNotNil(decryptedMessage)
        XCTAssertEqual(message, decryptedMessage)
    }
}
