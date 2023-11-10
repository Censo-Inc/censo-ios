//
//  PBKDF2.swift
//  Censo
//
//  Created by Ben Holzman on 11/15/23.
//

import Foundation
import CommonCrypto

func pbkdf2(password: String) -> Data? {
    guard let passwordData = password.data(using: .utf8) else { return nil }

    var derivedKeyData = Data(repeating: 0, count: 32)
    let derivedCount = derivedKeyData.count

    let derivationStatus: OSStatus = derivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
        let derivedKeyRawBytes = derivedKeyBytes.bindMemory(to: UInt8.self).baseAddress
        return CCKeyDerivationPBKDF(
            CCPBKDFAlgorithm(kCCPBKDF2),
            password,
            passwordData.count,
            nil,
            0,
            CCPBKDFAlgorithm(kCCPBKDF2),
            UInt32(120_000),
            derivedKeyRawBytes,
            derivedCount)
    }

    return derivationStatus == kCCSuccess ? derivedKeyData : nil
}
