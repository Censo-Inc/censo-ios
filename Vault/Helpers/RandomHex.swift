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
   let letters = "ABCDEF0123456789"
   let len = UInt32(letters.count)
   var random = SystemRandomNumberGenerator()
   var partitionId = ""
   for _ in 0..<lenght {
      let randomIndex = Int(random.next(upperBound: len))
      let randomCharacter = letters[letters.index(letters.startIndex, offsetBy: randomIndex)]
       partitionId.append(randomCharacter)
   }
    return partitionId
}
