//
//  HexString.swift
//  Censo
//
//  Created by Brendan Flood on 9/5/23.
//

import Foundation
import BigInt

extension ParticipantId {
    static func random() -> ParticipantId {
        ParticipantId(bigInt: generateParticipantId())
    }
}

func generateParticipantId() -> BigInt {
    return BigInt(generateRandomHex(lenght: 64), radix: 16)!
}
    
func generateRandomHex(lenght: Int) -> String {
    return generateRandom(letters: "ABCDEF0123456789", length: lenght)
}

func generateBase32() -> String {
    return generateRandom(letters: "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567", length: 16)
}

func generateRandom(letters: String, length: Int) -> String {
   let len = UInt32(letters.count)
   var random = SystemRandomNumberGenerator()
   var randomValue = ""
   for _ in 0..<length {
      let randomIndex = Int(random.next(upperBound: len))
      let randomCharacter = letters[letters.index(letters.startIndex, offsetBy: randomIndex)]
       randomValue.append(randomCharacter)
   }
    return randomValue
}
