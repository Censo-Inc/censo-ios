//
//  BigInt+Recovery.swift
//  Censo
//
//  Created by Ata Namvari on 2023-04-05.
//

import Foundation
import BigInt

extension BigInt {
    enum BigIntConversionError: Error {
        case badParticipantId
        case badRootSeed
        case badData
    }

    init(participantId: String) throws {
        guard let bigInt = BigInt(participantId, radix: 16) else {
            throw BigIntConversionError.badParticipantId
        }

        self = bigInt
    }

    init(rootSeed: [UInt8]) throws {
        guard let bigInt = BigInt(rootSeed.toHexString(), radix: 16) else {
            throw BigIntConversionError.badRootSeed
        }

        self = bigInt
    }

    init(data: Data) throws {
        guard let bigInt = BigInt(data.toHexString(), radix: 16) else {
            throw BigIntConversionError.badData
        }

        self = bigInt
    }
}

extension BigUInt {
    func to32PaddedHexString() -> String {
        return self.serialize().padded(toByteCount: 32).toHexString()
    }
}

extension Data {
    func padded(toByteCount byteCount: Int) -> Data {
        if count < byteCount {
            var paddedData = Data(repeating: 0, count: byteCount - count)
            paddedData.append(self)
            return paddedData
        } else {
            return self
        }
    }
}

