//
//  HexString.swift
//  Vault
//
//  Created by Brendan Flood on 9/5/23.
//

import Foundation
import BigInt

func generateParticipantId() -> BigInt {
    return BigInt(generateRandomHex(lenght: 64), radix: 16)!
}
    
func generateRandomHex(lenght: Int) -> String {
    return generateRandom(letters: "ABCDEF0123456789", lenght: lenght)
}

func generateBase32() -> String {
    return generateRandom(letters: "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789", lenght: 10).data(using: .utf8)!.base32String()
}

func generateRandom(letters: String, lenght: Int) -> String {
   let len = UInt32(letters.count)
   var random = SystemRandomNumberGenerator()
   var randomValue = ""
   for _ in 0..<lenght {
      let randomIndex = Int(random.next(upperBound: len))
      let randomCharacter = letters[letters.index(letters.startIndex, offsetBy: randomIndex)]
       randomValue.append(randomCharacter)
   }
    return randomValue
}
