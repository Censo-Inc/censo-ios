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

    func channel() -> String {
        return base64ToBase64Url(base64: Base64EncodedString(data: Data(SHA256.hash(data: importKey.data))))
    }
    
    static func fromURL(_ url: URL) throws -> Import {
        guard let scheme = url.scheme,
              scheme.starts(with: "censo-main"),
              url.host == "import" else {
            throw CensoError.invalidUrl(url: "\(url)")
        }
        guard let importKey = try? Base58EncodedPublicKey(value: url.pathComponents[2]),
              let timestamp = Int64(url.pathComponents[3]),
              let signature = try? Base64EncodedString(value: base64urlToBase64(base64url: url.pathComponents[4])),
              let nameBase64 = try? Base64EncodedString(value: base64urlToBase64(base64url: url.pathComponents[5])),
              let name = String(data: nameBase64.data, encoding: .utf8) else {
            throw CensoError.invalidUrl(url: "\(url)")
        }

        // if signature is in raw uncompressed form, convert to DER
        var derSignature: Data
        if (signature.data.count > 64) {
            derSignature = signature.data
        } else {
            func makePositive(_ input: Data) -> Data {
                if (input[0] > 0x7f) {
                    return Data([0x00] + input)
                } else {
                    return input
                }
            }
            let r = makePositive(signature.data.subdata(in: 0..<32))
            let s = makePositive(signature.data.subdata(in: 32..<64))
            derSignature = Data([0x30, UInt8(r.count + s.count + 4), 0x02, UInt8(r.count)] + r + [0x02, UInt8(s.count)] + s)
        }

        var signedData = Data(String(timestamp).utf8)
        signedData.append(Data(SHA256.hash(data: name.data(using: .utf8)!)))

        guard let verified = try? EncryptionKey.generateFromPublicExternalRepresentation(
                base58PublicKey: importKey).verifySignature(
            for: signedData,
            signature: Base64EncodedString(value: derSignature.base64EncodedString())) else {
            throw CensoError.invalidUrl(url: "\(url)")
        }
        if (verified) {
            let linkCreationTime = Date(timeIntervalSince1970: (Double(timestamp) / 1000))
            // allow a link which is from up to 10 seconds in the future,
            // to account for clock drift wherever the SDK is running
            let linkValidityStart = linkCreationTime.addingTimeInterval(-10)
            // link should be valid for 10 minutes
            let linkValidityEnd = linkCreationTime.addingTimeInterval(60 * 10)
            let now = Date()
            if (now > linkValidityEnd) {
                throw CensoError.linkExpired
            } else if (now < linkValidityStart) {
                throw CensoError.linkInFuture
            } else {
                return Import(importKey: importKey, timestamp: timestamp, signature: signature, name: name)
            }
        } else {
            throw CensoError.invalidUrl(url: "\(url)")
        }
    }
}

private func base64ToBase64Url(base64: Base64EncodedString) -> String {
    return base64.value
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
}

private func base64urlToBase64(base64url: String) -> String {
    var base64 = base64url
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")
    if base64.count % 4 != 0 {
        base64.append(String(repeating: "=", count: 4 - base64.count % 4))
    }
    return base64
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
