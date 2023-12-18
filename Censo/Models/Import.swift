//
//  Import.swift
//  Censo
//
//  Created by Ben Holzman on 12/7/23.
//

import Foundation
import CryptoKit

struct Import: Codable {
    var importKey: Base58EncodedPublicKey
    var timestamp: Int64
    var signature: Base64EncodedString
    var name: String

    private func base64ToBase64Url(base64: Base64EncodedString) -> String {
        return base64.value
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    func channel() -> String {
        return base64ToBase64Url(base64: Base64EncodedString(data: Data(SHA256.hash(data: importKey.data))))
    }
}

struct GetImportDataByKeyResponse: Codable {
    var importState: ImportState
}

struct ImportedPhrase: Codable {
    var binaryPhrase: BinaryPhrase
    var language: WordListLanguage
    var label: String? = nil
    
    enum ImportedPhraseCodingKeys: String, CodingKey {
        case binaryPhrase
        case language
        case label
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ImportedPhraseCodingKeys.self)
        self.binaryPhrase = try container.decode(BinaryPhrase.self, forKey: .binaryPhrase)
        self.language = WordListLanguage.fromId(id: try container.decode(UInt8.self, forKey: .language))
        self.label = try container.decode(String?.self, forKey: .label)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ImportedPhraseCodingKeys.self)
        try container.encode(binaryPhrase, forKey: .binaryPhrase)
        try container.encode(language.toId(), forKey: .language)
        try container.encode(label, forKey: .label)
    }
}

enum ImportState: Codable {
    case initial
    case accepted(Accepted)
    case completed(Completed)

    struct Accepted: Codable {
        var ownerDeviceKey: Base58EncodedPublicKey
        var ownerProof: Base64EncodedString
        var acceptedAt: Date
    }

    struct Completed: Codable {
        var encryptedData: Base64EncodedString
    }
    
    enum ImportStateCodingKeys: String, CodingKey {
        case type
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ImportStateCodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "Initial":
            self = .initial
        case "Accepted":
            self = .accepted(try Accepted(from: decoder))
        case "Completed":
            self = .completed(try Completed(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Import State")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ImportStateCodingKeys.self)
        switch self {
        case .initial:
            try container.encode("Initial", forKey: .type)
        case .accepted(let accepted):
            try container.encode("Accepted", forKey: .type)
            try accepted.encode(to: encoder)
        case .completed(let completed):
            try container.encode("Completed", forKey: .type)
            try completed.encode(to: encoder)
        }
    }
}
