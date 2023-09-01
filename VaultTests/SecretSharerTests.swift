//
//  SeedRecoveryTests.swift
//  CensoTests
//
//  Created by Ata Namvari on 2023-03-30.
//

import XCTest
import BigInt
@testable import Vault

final class SeedRecoveryTests: XCTestCase {

    func testSecretSharerSequentialSmallOrder() {
        var rnd = SystemRandomNumberGenerator()
        let order = 65537
        let secret = BigInt(BigUInt.randomInteger(withMaximumWidth: 16, using: &rnd))
        let seedRecovery = try! SecretSharer(
            secret: secret,
            threshold: 3,
            participants: (1...6).map({ BigInt($0) }),
            order: BigInt(order)
        )

        let shards = seedRecovery.shards

        XCTAssertEqual(
            secret,
            seedRecovery.recoverSecret(shares: [
                shards[0],
                shards[1],
                shards[2]
            ])
        )
    }

    func testSecretSharerOneParticipant() {
        var rnd = SystemRandomNumberGenerator()
        let secret = BigInt(BigUInt.randomInteger(withMaximumWidth: ORDER.magnitude.bitWidth, using: &rnd))
        let seedRecovery = try! SecretSharer(
            secret: secret,
            threshold: 1,
            participants: [BigInt(1)]
        )

        let shards = seedRecovery.shards

        XCTAssertEqual(
            secret,
            seedRecovery.recoverSecret(shares: [shards[0]])
        )

        XCTAssertEqual(
            secret,
            shards[0].y
        )
    }

    func testSecretSharerTwoParticipantAnd64ByteNumber() {
        let secret = BigInt("a3a4a523f3fcd16ab61fb7eba989e7b4155a5f960eb30877a5a4fdeaa7b8fd8373eb765067c15c50803bd5d141fa1b1a43fc7415bc664d34d6b3ce14db67daee", radix: 16)!
        let seedRecovery = try! SecretSharer(
            secret: secret,
            threshold: 2,
            participants: [
                BigInt(1),
                BigInt(2)
            ]
        )

        let shards = seedRecovery.shards

        XCTAssertEqual(
            secret,
            seedRecovery.recoverSecret(
                shares: [
                    shards[0],
                    shards[1]
                ]
            )
        )
    }

    func testSecretSharerRandom() {
        var rnd = SystemRandomNumberGenerator()
        let secret = BigInt(BigUInt.randomInteger(withMaximumWidth: ORDER.magnitude.bitWidth, using: &rnd))
        let seedRecovery = try! SecretSharer(
            secret: secret,
            threshold: 3,
            participants: (1...6).map { _ in BigInt(Int.random(in: 0...6000)) }
        )

        let shards = seedRecovery.shards

        XCTAssertEqual(
            secret,
            seedRecovery.recoverSecret(
                shares: [
                    shards[0],
                    shards[1],
                    shards[2]
                ]
            )
        )

        XCTAssertEqual(
            secret,
            seedRecovery.recoverSecret(
                shares: [
                    shards[2],
                    shards[4],
                    shards[5]
                ]
            )
        )

        XCTAssertNotEqual(
            secret,
            seedRecovery.recoverSecret(shares: [
                    shards[2],
                    shards[4]
                ]
            )
        )
    }

    private func assertMatrix(matrix: Matrix, expected: Int...) {
         var i = 0
         matrix.forEach { row in
             row.forEach { value in
                 XCTAssertEqual(
                    value,
                    BigInt(expected[i])
                 )

                 i += 1
             }
         }
    }

    func testMatrixInversion() {
        let seedRecovery = try! SecretSharer(
            secret: BigInt(1),
            threshold: 1,
            participants: [BigInt(1)],
            order: BigInt(65537)
        )

        let vandermonde = seedRecovery.vandermonde(participants: [7, 8, 9, 10].map({ BigInt($0) }), threshold: 4)
        let LUP = seedRecovery.decomposeLUP(matrix: vandermonde)
        let inverse = seedRecovery.invertLUP(lu: LUP.0, p: LUP.1)

         assertMatrix(
            matrix: inverse,
            expected: 120, 65222, 280, 65453,
             43651, 32880, 65434, 54646,
             32773, 65524, 32781, 65533,
             54614, 32769, 32768, 10923
         )
    }

    func testResharing() {
        var rnd = SystemRandomNumberGenerator()
        let secret = BigInt(BigUInt.randomInteger(withMaximumWidth: ORDER.magnitude.bitWidth, using: &rnd))
        let participants = (1...6).map({ BigInt($0) })
        let sharer = try! SecretSharer(
            secret: secret,
            threshold: 3,
            participants: participants
        )

        let newParticipants = (7...12).map({ BigInt($0) })
        let reshares = try! sharer.getReshares(newParticipants: newParticipants, newThreshold: 4)
        let vandermonde = sharer.vandermonde(participants: Array(participants.prefix(3)), threshold: 3)
        let LUP = sharer.decomposeLUP(matrix: vandermonde)
        let vandermondeInverse = sharer.invertLUP(lu: LUP.0, p: LUP.1)
        let newShares = newParticipants.enumerated().map { i, part in
            Point(x: part, y: sharer.addShares(shares: reshares.map({ $0[i].y }), weights: vandermondeInverse[0]))
        }

        XCTAssertEqual(
            secret,
            sharer.recoverSecret(
                shares: [
                    newShares[0],
                    newShares[1],
                    newShares[2],
                    newShares[3]
                ]
            )
        )

        XCTAssertEqual(
            secret,
            sharer.recoverSecret(
                shares: [
                    newShares[1],
                    newShares[2],
                    newShares[3],
                    newShares[4]
                ]
            )
        )

        XCTAssertNotEqual(
            secret,
            sharer.recoverSecret(
                shares: [
                    newShares[1],
                    newShares[2],
                    newShares[3]
                ]
            )
        )
    }
}

typealias Key = String
typealias Sid = String
typealias Pid = BigInt
typealias Revision = String

struct Shard: Hashable {
    var sid: Sid
    var pid: Pid
    var threshold: Int
    var shard: BigInt
    var revision: Revision
    var email: String
    var parentShards: [Shard]?
}

