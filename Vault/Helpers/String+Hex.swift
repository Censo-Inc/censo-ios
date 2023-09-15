//
//  String+Hex.swift
//  Strike
//
//  Created by Benjamin Holzman on 11/23/22.
//

import Foundation

extension String {
    enum ExtendedEncoding {
        case hexadecimal
    }

    func data(using encoding:ExtendedEncoding) -> Data? {
        switch encoding {
        case .hexadecimal:
            let hexStr = self.dropFirst(self.hasPrefix("0x") ? 2 : 0)

            let paddedStr = hexStr.count.isMultiple(of: 2) ? hexStr : "0" + hexStr
            var newData = Data(capacity: paddedStr.count/2)

            var indexIsEven = true
            for i in paddedStr.indices {
                if indexIsEven {
                    let byteRange = i...paddedStr.index(after: i)
                    guard let byte = UInt8(paddedStr[byteRange], radix: 16) else { return nil }
                    newData.append(byte)
                }
                indexIsEven.toggle()
            }
            return newData
        }
    }

}
