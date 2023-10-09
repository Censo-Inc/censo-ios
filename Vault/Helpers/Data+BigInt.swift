//
//  Data+BigInt.swift
//  Vault
//
//  Created by Anton Onyshchenko on 09.10.23.
//

import Foundation
import BigInt

extension Data {
    public func toPositiveBigInt() -> BigInt {
        return BigInt(sign: .plus, magnitude: BigUInt(self))
    }
}
