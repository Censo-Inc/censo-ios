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
