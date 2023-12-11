//
//  BIP39.swift
//  Censo
//
//  Created by Ben Holzman on 10/16/23.
//

import Foundation
import CryptoKit

enum BIP39InvalidReason: Equatable, Error {
    case invalidWords(wordsByIndex: [Int: String])
    case tooShort(wordCount: Int)
    case tooLong(wordCount: Int)
    case badLength(wordCount: Int)
    case invalidChecksum
}

extension BIP39InvalidReason {
    
    private func phraseLength(count: Int) -> String {
        return "You entered a seed phrase that was \(count) \(count == 1 ? "word" : "words") long."
    }
    
    public var description: String {
        switch (self) {
        case .tooShort(let count):
            return """
\(phraseLength(count: count))

Seed phrases are typically 12 or 24 words long.

Please check your seed phrase and try again.
"""
        case .tooLong(let count):
            return """
\(phraseLength(count: count))

Seed phrases are typically 12 or 24 words long.

Please check your seed phrase and try again.
"""
        case .badLength(let count):
            return """
\(phraseLength(count: count))

Seed phrases must be either 12, 15, 18, 21, or 24 words long.

Please check your seed phrase and try again.
"""
        case .invalidChecksum:
            return """
The seed phrase you entered is not valid.

Please check your seed phrase and try again.
"""
        case .invalidWords(let wordsByIndex):
            return """
The seed phrase you entered contains words which are not valid:

\(wordsByIndex.values.joined(separator: ", "))

Please check your seed phrase and try again.
"""
        }
    }
    
    public var title: String {
        switch (self) {
        case .tooShort:
            return "Seed phrase too short"
        case .tooLong:
            return "Seed phrase too long"
        case .badLength:
            return "Incorrect number of words"
        case .invalidChecksum:
            return "Invalid seed phrase"
        case .invalidWords:
            return "Invalid words"
        }
    }
}

public enum WordCount: Int {
    case twelve = 12
    case fifteen = 15
    case eighteen = 18
    case twentyOne = 21
    case twentyFour = 24
}

extension BIP39 {
    // 1-of-2048 is 11 bits
    static var bitsPerWord = 11

    // Returns a byte with the MSB bits set
    private static func getUpperMask(bits: UInt8) -> UInt8 {
       return (UInt8(UInt16(1 << bits) - 1)) << (8 - bits);
    }

    static func splitToWords(phrase: String) -> [String] {
        let normalizedPhrase = phrase.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        // 0x3000 is unicode for space in ideographic langauges (symbol based languages like japaneses)
        return normalizedPhrase.split(whereSeparator: { $0 == "\u{3000}" || $0 == " " || $0 == "\n"}).map(String.init)
    }

    private static func getBitLengths(count: Int) -> (Int, Int) {
        let totalBits = count * Self.bitsPerWord
        let checksumBits = count / 3
        let entropyBits = totalBits - checksumBits
        return (entropyBits, checksumBits)
    }

    private static func getWordCount(bitLength: Int) -> Int {
        return bitLength / bitsPerWord
    }

    static func validateSeedPhrase(phrase: String) -> BIP39InvalidReason? {
        let words = Self.splitToWords(phrase: phrase)
        return Self.validateSeedPhrase(words: words, language: determineLanguage(phrase: phrase))
    }
    
    static func determineLanguage(phrase: String) -> WordListLanguage {
        return determineLanguageForWords(words: BIP39.splitToWords(phrase: phrase))
    }
    
    static func determineLanguageForWords(words: [String]) -> WordListLanguage {
        for word in words {
            let candidates = WordListLanguage.allCases.filter({
                let wordlist = wordlists($0)
                if let _ = wordlist.firstIndex(of: String(word)) {
                    return true
                } else {
                    return false
                }
            })
            if candidates.count == 1 || (candidates.count > 1 && word == words.last) {
                return candidates[0]
            }
        }
        return .english
    }

    static func validateSeedPhrase(words: [any StringProtocol], language: WordListLanguage = .english) -> BIP39InvalidReason? {
        if (words.count < 12) {
            return BIP39InvalidReason.tooShort(wordCount: words.count)
        }
        if (words.count > 24) {
            return BIP39InvalidReason.tooLong(wordCount: words.count)
        }
        if (!words.count.isMultiple(of: 3)) {
            return BIP39InvalidReason.badLength(wordCount: words.count)
        }

        let (entropyBits, checksumBits) = getBitLengths(count: words.count)

        // calculate the binary representation of the phrase
        let wordlist = wordlists(language)
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
        let expectedChecksum = (Data(SHA256.hash(data: entropyBinary ?? Data())).bytes.first! & getUpperMask(bits: UInt8(checksumBits))) >> (8 - checksumBits)

        // Compare the calculated checksum with the expected checksum
        if (checksumBinary != expectedChecksum) {
            return BIP39InvalidReason.invalidChecksum
        }

        return nil
    }

    static func phraseToBinaryData(words: [String]) throws -> Data {
        let language = determineLanguageForWords(words: words)
        var binaryPhrase: String = ""
        let wordlist = wordlists(language)
        for word in words {
            if let indexInList = wordlist.firstIndex(of: String(word)) {
                let binaryIndex = String(indexInList, radix: 2).pad(toSize: bitsPerWord)
                binaryPhrase += binaryIndex
            } else {
                throw CensoError.failedToEncodeSecrets
            }
        }

        let (entropyBits, checksumBits) = getBitLengths(count: words.count)

        guard let entropyBinary = String(binaryPhrase.prefix(entropyBits)).binaryToData(),
              let checksumBinary = String(binaryPhrase.suffix(checksumBits)).binaryToData()?.bytes.last else {
            throw CensoError.failedToEncodeSecrets
        }
        let expectedChecksum = (Data(SHA256.hash(data: entropyBinary)).bytes.first! & getUpperMask(bits: UInt8(checksumBits))) >> (8 - checksumBits)

        if (checksumBinary != expectedChecksum) {
            throw CensoError.failedToEncodeSecrets
        }

        return Data([language.toId()]) + entropyBinary
    }
    
    static func generatePhrase(wordCount: WordCount, language: WordListLanguage) throws -> [String] {
        let entropyBitsCount = wordCount.rawValue / 3 * 32
        var entropy = [UInt8](repeating: 0, count: entropyBitsCount / 8)
        if SecRandomCopyBytes(kSecRandomDefault, entropy.count, &entropy) != 0 {
            throw CensoError.failedToGenerateSeedPhrase
        }
        return try binaryDataToWords(binaryData: Data([language.toId()] + entropy))
    }
    
    static func binaryDataToWords(binaryData: Data, language: WordListLanguage? = nil) throws -> [String] {
        let binaryEntropy = binaryData.suffix(from: 1)
        // compute checksum
        let checksumBits = binaryEntropy.count / 4
        let checksum = String(Data(SHA256.hash(data: binaryEntropy)).toBinaryString().prefix(checksumBits))

        var wordlist: [String]
        switch (language) {
        case .none:
            let languageId = binaryData.prefix(upTo: 1).bytes[0]
            wordlist = wordlists(WordListLanguage.fromId(id: languageId))
        case .some(let lang):
            wordlist = wordlists(lang)
        }
        let binaryPhrase = binaryEntropy.suffix(from: 1).toBinaryString() + checksum

        var words: [String] = []
        var startIndex = binaryPhrase.startIndex
        let wordCount = binaryPhrase.count / 11
        for _ in 1...wordCount {
            let endIndex = binaryPhrase.index(startIndex, offsetBy: bitsPerWord)
            let wordIndexBinaryString = String(binaryPhrase[startIndex..<endIndex])
            var wordIndex: UInt16 = 0
            var bitValue: UInt16 = 1 << (bitsPerWord - 1)
            wordIndexBinaryString.forEach { bit in
                wordIndex += bit == "1" ? bitValue : 0
                bitValue >>= 1
            }
            words.append(wordlist[Int(wordIndex)])
            startIndex = endIndex
        }
        return words
    }
}

// String extension to pad binary representation to a specific size
fileprivate extension String {
    func pad(toSize: Int) -> String {
        var padded = self
        while padded.count < toSize {
            padded = "0" + padded
        }
        return padded
    }

    func binaryToData() -> Data? {
        var newData = Data(capacity: max(1, self.count / 8))

        for i in stride(from: 0, to: self.count, by: 8) {
            let start = self.index(self.startIndex, offsetBy: i)
            let end = i + 8 < self.count ? self.index(self.startIndex, offsetBy: i + 8) : self.endIndex
            guard let byte = UInt8(self[start..<end], radix: 2) else { return nil } // why would this happen?
            newData.append(byte)
        }
        return newData
    }
}

extension Data {
    func toBinaryString() -> String {
        return self.reduce("") { (result, byte) in
            return result + String(byte, radix: 2).pad(toSize: 8)
        }
    }
}

enum WordListLanguage: CaseIterable {
    case english
    case spanish
    case french
    case italian
    case portugese
    case czech
    case japanese
    case korean
    case chineseTraditional
    case chineseSimplified
}

extension WordListLanguage {
    func toId() -> UInt8 {
        switch (self) {
        case .english:
            return 1
        case .spanish:
            return 2
        case .french:
            return 3
        case .italian:
            return 4
        case .portugese:
            return 5
        case .czech:
            return 6
        case .japanese:
            return 7
        case .korean:
            return 8
        case .chineseTraditional:
            return 9
        case .chineseSimplified:
            return 10
        }
    }

    static func fromId(id: UInt8) -> WordListLanguage {
        switch (id) {
        case 1:
            return .english
        case 2:
            return spanish
        case 3:
            return .french
        case 4:
            return .italian
        case 5:
            return .portugese
        case 6:
            return .czech
        case 7:
            return .japanese
        case 8:
            return .korean
        case 9:
            return .chineseTraditional
        case 10:
            return .chineseSimplified
        default:
            return .english
        }
    }
    
    func displayName() -> String {
        switch (self) {
        case .english:
            return "English"
        case .spanish:
            return "Spanish"
        case .french:
            return "French"
        case .italian:
            return "Italian"
        case .portugese:
            return "Portugese"
        case .czech:
            return "Czech"
        case .japanese:
            return "Japanese"
        case .korean:
            return "Korean"
        case .chineseTraditional:
            return "Chinese (Traditional)"
        case .chineseSimplified:
            return "Chinese (Simplified)"
        }
    }
    
    func localizedDisplayName() -> String {
        switch (self) {
        case .english:
            return "English"
        case .spanish:
            return "Español"
        case .french:
            return "Français"
        case .italian:
            return "Italiano"
        case .portugese:
            return "Português"
        case .czech:
            return "Čeština"
        case .japanese:
            return "日本語"
        case .korean:
            return "한국어"
        case .chineseTraditional:
            return "中文(繁體)"
        case .chineseSimplified:
            return "中文(简体)"
        }
    }
    
    func unicodeSpace() -> UInt32? {
        switch (self) {
        case .japanese:
            return 0x3000
        default:
            return nil
        }
    }
    
}

struct BIP39 {
    
    struct WordLists: Codable {
        var english: [String]
        var spanish: [String]
        var french: [String]
        var italian: [String]
        var portugese: [String]
        var czech: [String]
        var japanese: [String]
        var korean: [String]
        var chineseSimplified: [String]
        var chineseTraditional: [String]
    }

    
    static func wordlists(_ language: WordListLanguage) -> [String] {
        switch (language) {
        case .english:
            return wordLists.english
        case .spanish:
            return wordLists.spanish
        case .french:
            return wordLists.french
        case .italian:
            return wordLists.italian
        case .portugese:
            return wordLists.portugese
        case .czech:
            return wordLists.czech
        case .japanese:
            return wordLists.japanese
        case .korean:
            return wordLists.korean
        case .chineseSimplified:
            return wordLists.chineseSimplified
        case .chineseTraditional:
            return wordLists.chineseTraditional
        }
    }
    
    private static var wordLists = {
        if let jsonPath: String = Bundle.main.path(forResource: "bip39words", ofType: "json"),
            let jsonData: Data = NSData(contentsOfFile: jsonPath) as? Data {
            do {
                return try JSONDecoder().decode(WordLists.self, from: jsonData)
            } catch {
                debugPrint("Error while deserialization of jsonData \(error)")
            }
        }
        return WordLists(english: [], spanish: [], french: [], italian: [], portugese: [], czech: [], japanese: [], korean: [], chineseSimplified: [], chineseTraditional: []
        )
    }()
}

