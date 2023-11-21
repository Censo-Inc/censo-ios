//
//  Base58Tests.swift
//  CensoTests
//
//  Created by Ben Holzman on 11/21/23.
//

import XCTest

final class Base58Tests: XCTestCase {
    func getTestCases() -> [Data: String] {
        // all byte values
        var allBytes = Data(capacity: 256)
        for ix in 0...255 {
            allBytes.append(UInt8(ix))
        }
        return [
            // empty
            Data(): "",
            // single null byte
            Data([UInt8(0)]): "1",
            // two null bytes
            Data([UInt8(0), UInt8(0)]): "11",
            // 1-byte followed by 0-byte
            Data([UInt8(1), UInt8(0)]): "5R",
            // single 255-byte
            Data([UInt8(255)]): "5Q",
            // two 255-bytes
            Data([UInt8(255), UInt8(255)]): "LUv",
            allBytes: "1cWB5HCBdLjAuqGGReWE3R3CguuwSjw6RHn39s2yuDRTS5NsBgNiFpWgAnEx6VQi8csexkgYw3mdYrMHr8x9i7aEwP8kZ7vccXWqKDvGv3u1GxFKPuAkn8JCPPGDMf3vMMnbzm6Nh9zh1gcNsMvH3ZNLmP5fSG6DGbbi2tuwMWPthr4boWwCxf7ewSgNQeacyozhKDDQQ1qL5fQFUW52QKUZDZ5fw3KXNQJMcNTcaB723LchjeKun7MuGW5qyCBZYzA1KjofN1gYBV3NqyhQJ3Ns746GNuf9N2pQPmHz4xpnSrrfCvy6TVVz5d4PdrjeshsWQwpZsZGzvbdAdN8MKV5QsBDY"
        ]
    }

    func testBase58Encode() {
        for testCase in getTestCases() {
            XCTAssertEqual(Base58.encode(testCase.key.bytes), testCase.value)
        }
    }
    
    func testBase58Decode() {
        for testCase in getTestCases() {
            XCTAssertEqual(Base58.decode(testCase.value), testCase.key.bytes)
        }
    }
}
