//
//  Data+Hex.swift
//  Censo
//
//  Created by Ata Namvari on 2021-04-28.
//

import Foundation

extension Data {
    public var bytes: Array<UInt8> {
      Array(self)
    }

    public func toHexString() -> String {
      self.bytes.toHexString()
    }
}


extension Array where Element == UInt8 {
  public func toHexString() -> String {
    `lazy`.reduce(into: "") {
      var s = String($1, radix: 16)
      if s.count == 1 {
        s = "0" + s
      }
      $0 += s
    }
  }
}

extension String {
    func hexData() -> Data? {
        let hexStr = self.dropFirst(self.hasPrefix("0x") ? 2 : 0)
        
        var newData = Data(capacity: hexStr.count/2)
        
        var indexIsEven = true
        for i in hexStr.indices {
            if indexIsEven {
                let byteRange = i...hexStr.index(after: i)
                guard let byte = UInt8(hexStr[byteRange], radix: 16) else { return nil }
                newData.append(byte)
            }
            indexIsEven.toggle()
        }
        return newData
    }
}
