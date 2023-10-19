//
//  BIP39.swift
//  Vault
//
//  Created by Ben Holzman on 10/16/23.
//

import Foundation
import CryptoKit

enum BIP39InvalidReason: Equatable {
    case invalidWords(wordsByIndex: [Int: String])
    case tooShort
    case tooLong
    case badLength
    case invalidChecksum
}

extension BIP39InvalidReason: CustomStringConvertible {
    public var description: String {
        switch (self) {
        case .tooShort:
            return "Phrase must be at least 12 words long"
        case .tooLong:
            return "Phrase must be no more than 24 words long"
        case .badLength:
            return "Phrase must have 12, 15, 18, 21, or 24 words"
        case .invalidChecksum:
            return "Phrase is not valid"
        case .invalidWords(let wordsByIndex):
            return "Phrase contains invalid words: \(wordsByIndex.values.joined(separator: ", "))"
        }
    }
}

fileprivate let wordlist: [String] = {
    if let path = Bundle.main.path(forResource: "bip39", ofType: "json") {
        let data = try? Data(contentsOf: URL(fileURLWithPath: path))
        switch (data) {
        case .none:
            return []
        case .some(let data):
            return (try? JSONSerialization.jsonObject(with: data, options: []) as? [String]) ?? []
        }
    } else {
        return []
    }
}()

struct BIP39Validator {
    // Returns a byte with the MSB bits set
    private func getUpperMask(bits: UInt8) -> UInt8 {
       return (UInt8(UInt16(1 << bits) - 1)) << (8 - bits);
    }

    private func splitToWords(phrase: String) -> [String] {
        var words = [String]()

        phrase.enumerateSubstrings(in: phrase.startIndex..<phrase.endIndex, options: .byWords) { (substring, _, _, _) -> () in
            words.append(substring!)
        }

        return words
    }

    func validateSeedPhrase(phrase: String) -> BIP39InvalidReason? {
        let normalizedPhrase = phrase.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let words = splitToWords(phrase: normalizedPhrase)

        if (words.count < 12) {
            return BIP39InvalidReason.tooShort
        }
        if (words.count > 24) {
            return BIP39InvalidReason.tooLong
        }
        if (!words.count.isMultiple(of: 3)) {
            return BIP39InvalidReason.badLength
        }

        // 1-of-2048 is 11 bits
        let totalBits = words.count * 11
        let checksumBits = words.count / 3
        let entropyBits = totalBits - checksumBits

        // calculate the binary representation of the phrase
        var binaryPhrase: String = ""
        var invalidWords: [Int: String] = [:]
        for (index, word) in words.enumerated() {
            if let indexInList = wordlist.firstIndex(of: String(word)) {
                let binaryIndex = String(indexInList, radix: 2).pad(toSize: 11)
                binaryPhrase += binaryIndex
            } else {
                invalidWords[index] = String(word)
            }
        }
        if (!invalidWords.isEmpty) {
            return BIP39InvalidReason.invalidWords(wordsByIndex: invalidWords)
        }

        // the layout of binaryPhrase is the entropy bits first followed by the checksum bits
        let entropyBinary = String(binaryPhrase.prefix(entropyBits)).binaryToData()
        let checksumBinary = String(binaryPhrase.suffix(checksumBits)).binaryToData()?.bytes.last

        // Calculate the expected checksum based on the entropy
        let expectedChecksum = Data(SHA256.hash(data: entropyBinary ?? Data())).bytes.first! & getUpperMask(bits: UInt8(checksumBits))

        // Compare the calculated checksum with the expected checksum
        if (checksumBinary != expectedChecksum) {
            return BIP39InvalidReason.invalidChecksum
        }

        return nil
    }
}

// String extension to pad binary representation to a specific size
extension String {
    func pad(toSize: Int) -> String {
        var padded = self
        while padded.count < toSize {
            padded = "0" + padded
        }
        return padded
    }

    func binaryToData() -> Data? {
        var newData = Data(capacity: self.count / 8)

        for i in stride(from: 0, to: self.count, by: 8) {
            let start = self.index(self.startIndex, offsetBy: i)
            let end = i + 8 < self.count ? self.index(self.startIndex, offsetBy: i + 8) : self.endIndex
            guard let byte = UInt8(self[start..<end], radix: 2) else { return nil } // why would this happen?
            newData.append(byte)
        }
        return newData
    }
}