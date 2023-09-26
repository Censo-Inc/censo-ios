//
//  TotpUtils.swift
//  Vault
//
//  Created by Brendan Flood on 9/14/23.
//

import Foundation
import CryptoKit

struct TotpUtils {

    static let period = TimeInterval(60)
    static let digits = 6

    static func getOTP(date: Date, secret: Data) ->  String {
        var counter = UInt64(date.timeIntervalSince1970 / period).bigEndian
        // Generate the key based on the counter.
        let key = SymmetricKey(data: Data(bytes: &counter, count: MemoryLayout.size(ofValue: counter)))
        let hash = HMAC<Insecure.SHA1>.authenticationCode(for: secret, using: key)

        var truncatedHash = hash.withUnsafeBytes { ptr -> UInt32 in
            let offset = ptr[hash.byteCount - 1] & 0x0f

            let truncatedHashPtr = ptr.baseAddress! + Int(offset)
            return truncatedHashPtr.bindMemory(to: UInt32.self, capacity: 1).pointee
        }

        truncatedHash = UInt32(bigEndian: truncatedHash)
        truncatedHash = truncatedHash & 0x7FFF_FFFF
        truncatedHash = truncatedHash % UInt32(pow(10, Float(digits)))

        return String(format: "%0*u", digits, truncatedHash)
    }
    
    static func getRemainingSeconds(date: Date) -> Int {
        let remainder = Int(UInt64(date.timeIntervalSince1970.rounded()) % UInt64(period.rounded()))
        return Int(period.rounded()) - remainder
    }
    
    static func getPercentDone(date: Date) -> Double {
        let remainder = UInt64(date.timeIntervalSince1970.rounded()) % UInt64(period.rounded())
        return Double(remainder) / period
    }
}
