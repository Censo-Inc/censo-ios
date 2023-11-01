//
//  ValueWrappers.swift
//  Censo
//
//  Created by Brendan Flood on 9/15/23.
//

import Foundation
import BigInt

enum ValueWrapperError: Error {
    case invalidBase58
    case invalidBase64
    case invalidParticipantId
    case invalidInvitationId
}

struct Base58EncodedPublicKey: Codable, Equatable {
    var value: String
    var data: Data
    
    init(value: String) throws {
        let data = Base58.decode(value)
        if data.count != 33 && data.count != 65 {
            throw ValueWrapperError.invalidBase58
        }
        self.value = value
        self.data = Data(data)
    }
    
    init(data: Data) throws {
        self.value = Base58.encode([UInt8](data))
        self.data = data
    }
    
    init(from decoder: Decoder) throws {
        var container = try decoder.singleValueContainer()
        do {
            self = try Base58EncodedPublicKey(value: try container.decode(String.self))
        } catch {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid Base58 Key")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

struct Base64EncodedString: Codable, Equatable {
    var value: String
    var data: Data
    
    init(value: String) throws {
        guard let data = Data(base64Encoded: value) else {
            throw ValueWrapperError.invalidBase64
        }
        self.value = value
        self.data = data
    }
    
    init(data: Data) {
        self.value = data.base64EncodedString()
        self.data = data
    }
    
    init(from decoder: Decoder) throws {
        var container = try decoder.singleValueContainer()
        do {
            self = try Base64EncodedString(value: try container.decode(String.self))
        } catch {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid Base64 data")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

struct ParticipantId: Codable, Equatable, Hashable {
    var value: String
    var bigInt: BigInt
    
    init(value: String) throws {
        guard let data = value.data(using: .hexadecimal),
              let bigInt = BigInt(value, radix: 16) else {
            throw ValueWrapperError.invalidParticipantId
        }
        if data.count != 32 {
            throw ValueWrapperError.invalidParticipantId
        }
        self.value = value
        self.bigInt = bigInt
    }
    
    init(bigInt: BigInt) {
        self.value = bigInt.magnitude.to32PaddedHexString()
        self.bigInt = bigInt
    }
    
    init(from decoder: Decoder) throws {
        var container = try decoder.singleValueContainer()
        do {
            self = try ParticipantId(value: try container.decode(String.self))
        } catch {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ParticipantId")
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
    
}
