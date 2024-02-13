//
//  SeedPhrase.swift
//  Censo
//
//  Created by Brendan Flood on 1/19/24.
//

import Foundation

private let phraseHeaderByte: UInt8 = 255
private let imageTypeCode: UInt8 = 1

enum SeedPhrase {
    case image(imageData: Data)
    case bip39(words: [String])
}

extension SeedPhrase {
    
    func toData() throws -> Data {
        switch self {
        case .image(let imageData):
            return Data([phraseHeaderByte, imageTypeCode]) + imageData
        case .bip39(let words):
            return try BIP39.phraseToBinaryData(words: words)
        }
    }

    static func fromData(data: Data, language: WordListLanguage? = nil) throws -> SeedPhrase {
        if data.count < 2 {
            throw CensoError.invalidPhraseData
        }
        switch (data[0]) {
        case phraseHeaderByte:
            switch data[1] {
            case imageTypeCode:
                return .image(imageData: data.dropFirst(2))
            default:
                throw CensoError.invalidPhraseData
            }
        default:
            return .bip39(words: try BIP39.binaryDataToWords(binaryData: data, language: language))
        }
    }
    
}

enum SeedPhraseType: String, Codable {
    case binary = "Binary"
    case photo = "Photo"
}
