//
//  SecretSharer.swift
//  Censo
//
//  Created by Ata Namvari on 2023-03-29.
//

import Foundation
import BigInt

struct Point {
    var x: BigInt
    var y: BigInt

    init(x: BigInt, y: BigInt) {
        self.x = x
        self.y = y
    }

    init(x: String, y: String) {
        self.x = BigInt(stringLiteral: x)
        self.y = BigInt(stringLiteral: y)
    }

    init(x: String, y: BigInt) {
        self.x = BigInt(stringLiteral: x)
        self.y = y
    }

    init(x: BigInt, y: String) {
        self.x = x
        self.y = BigInt(stringLiteral: y)
    }
}

typealias Vector = Array<BigInt>
typealias Matrix = Array<Vector>

var ORDER = BigInt("13407807929942597099574024998205846127479365820592393377723561443721764030073546976801874298166903427690031858186486050853753882811946569946433649006083527")
private var rnd = SystemRandomNumberGenerator()

struct SecretSharerUtils {
    static func randomFieldElement(order: BigInt) -> BigInt {
        var randomNumber: BigInt

        repeat {
            randomNumber = BigInt(sign: .plus, magnitude: BigUInt.randomInteger(withMaximumWidth: order.magnitude.bitWidth, using: &rnd))
        } while (randomNumber >= order)

        return randomNumber
    }

    static func vandermonde(participants: [BigInt], threshold: Int, order: BigInt) -> Matrix {
        var matrix = Matrix(repeating: [], count: participants.count)

        for p in 0..<matrix.count {
            var vector = Vector(repeating: .zero, count: threshold)

            for t in 0..<vector.count {
                vector[t] = participants[p].power(BigInt(t), modulus: order)
            }

            matrix[p] = vector
        }

        return matrix
    }

    static func dotProduct(matrix: Matrix, vector: Vector, order: BigInt) -> Vector {
        var result = Vector(repeating: .zero, count: matrix.count)

        for i in 0..<matrix.count {
            let row = matrix[i]

            for j in 0..<row.count {
                let value = row[j]
                result[i] = (result[i] + (value * vector[j])).modulus(order)
            }
        }

        return result
    }

    static func recoverSecret(shares: [Point], order: BigInt = ORDER) -> BigInt {
        var van = vandermonde(participants: shares.map { $0.x }, threshold: shares.count, order: order)
        var (lu, p) = decomposeLUP(matrix: van, order: order)
        var inverse = invertLUP(lu: lu, p: p, order: order)
        return addShares(shares: shares.map { $0.y }, weights: inverse[0], order: order)
    }

    static func addShares(shares: [BigInt], weights: [BigInt], order: BigInt) -> BigInt {
        return shares.enumerated().map { i, s in s * weights[i] }.reduce(.zero) { a, b in (a + b).modulus(order) }
    }

    // below inspired by https://en.wikipedia.org/wiki/LU_decomposition#C_code_example
    /*
     * Decomposes matrix into an LUP factorization, returning LU as a single matrix,
     * and P as a vector
     */
    static func decomposeLUP(matrix: Matrix, order: BigInt) -> (Matrix, Vector) {
        var n = matrix.count
        matrix.forEach { row in assert(row.count == n, "Matrix must be square") }
        var lu = matrix
        // Unit permutation matrix, p[i] initialized with i
        var p = Vector(repeating: .zero, count: n)
        for i in 0..<p.count {
            p[i] = BigInt(i)
        }

        (0..<n).forEach { i in
            var maxA = BigUInt.zero
            var iMax = i
            (i..<n).forEach { k in
                var absA = matrix[k][i].magnitude
                if (absA > maxA) {
                    maxA = absA
                    iMax = k
                }
            }

            assert(maxA > BigInt.zero, "Matrix is degenerate")

            if (iMax != i) {
                // pivoting P
                let tempP = p[i]
                p[i] = p[iMax]
                p[iMax] = tempP

                // pivoting rows of A
                let tempLU = lu[i]
                lu[i] = lu[iMax]
                lu[iMax] = tempLU
            }

            ((i + 1)..<n).forEach { j in
                lu[j][i] = divMod(numerator: lu[j][i], denominator: lu[i][i], order: order).modulus(order)
                ((i + 1)..<n).forEach { k in
                    lu[j][k] = (lu[j][k] - lu[j][i] * lu[i][k]).modulus(order)
                }
            }
        }

        return (lu, p)
    }

    /*
     *  Division in integers modulus p means finding the inverse of the
     *  denominator modulo p and then multiplying the numerator by this
     *  inverse (Note: inverse of A is B such that A*B % p == 1). This can
     *  be computed via the extended Euclidean algorithm
     *  http://en.wikipedia.org/wiki/Modular_multiplicative_inverse#Computation
     */

    static private func divMod(numerator: BigInt, denominator: BigInt, order: BigInt) -> BigInt {
        let inverse = extendedGCD(aIn: denominator, bIn: order)
        return numerator * inverse
    }

    static private func extendedGCD(aIn: BigInt, bIn: BigInt) -> BigInt {
        var a = BigInt(sign: .plus, magnitude: BigUInt(words: aIn.words))
        var b = BigInt(sign: .plus, magnitude: BigUInt(words: bIn.words))
        var x = BigInt.zero
        var lastX = BigInt(1)
        var y = BigInt(1)
        var lastY = BigInt.zero
        while (b != BigInt.zero) {
            let quotient = a / b
            let oldA = a
            a = b
            b = oldA.modulus(b)

            let oldLastX = lastX
            lastX = x
            x = oldLastX - quotient * x

            let oldLastY = lastY
            lastY = y
            y = oldLastY - quotient * x
        }
        return lastX
    }

    /*
     * Takes an LU matrix and a P permutation vector, returns the inverse matrix
     */
    static func invertLUP(lu: Matrix, p: Vector, order: BigInt) -> Matrix {
        let n = lu.count
        var inverse = Matrix(repeating: Vector(repeating: .zero, count: n), count: n)
        (0..<n).forEach { j in
            (0..<n).forEach { i in
                inverse[i][j] = (p[i] == BigInt(j)) ? BigInt(1) : BigInt.zero
                (0..<i).forEach { k in
                    inverse[i][j] = inverse[i][j] - lu[i][k] * inverse[k][j]
                    inverse[i][j] = inverse[i][j].modulus(order)
                }
            }
            (0..<n).reversed().forEach { i in
                ((i + 1)..<n).forEach { k in
                    inverse[i][j] = inverse[i][j] - lu[i][k] * inverse[k][j]
                    inverse[i][j] = inverse[i][j].modulus(order)
                }
                inverse[i][j] = divMod(numerator: inverse[i][j], denominator: lu[i][i], order: order)
                inverse[i][j] = inverse[i][j].modulus(order)
            }
        }
        return inverse
    }
}

struct SecretSharer {
    var secret: BigInt
    var threshold: Int
    var participants: [BigInt]
    var order = ORDER
    var shards: [Point]

    init(
        secret: BigInt,
        threshold: Int,
        participants: [BigInt],
        order: BigInt = ORDER
    ) throws {
        self.secret = secret
        self.threshold = threshold
        self.participants = participants
        self.order = order
        self.shards = []
        self.shards = try getShares(participants: participants, threshold: threshold, secret: secret)
    }

    func vandermonde(participants: [BigInt], threshold: Int) -> Matrix {
        SecretSharerUtils.vandermonde(participants: participants, threshold: threshold, order: order)
    }

    func dotProduct(matrix: Matrix, vector: Vector) -> Vector {
        SecretSharerUtils.dotProduct(matrix: matrix, vector: vector, order: order)
    }

    func recoverSecret(shares: [Point]) -> BigInt {
        SecretSharerUtils.recoverSecret(shares: shares, order: order)
    }

    func addShares(shares: [BigInt], weights: [BigInt]) -> BigInt {
        SecretSharerUtils.addShares(shares: shares, weights: weights, order: order)
    }

    func decomposeLUP(matrix: Matrix) -> (Matrix, Vector) {
        SecretSharerUtils.decomposeLUP(matrix: matrix, order: order)
    }

    func invertLUP(lu: Matrix, p: Vector) -> Matrix {
        SecretSharerUtils.invertLUP(lu: lu, p: p, order: order)
    }

    enum ShareError: Error {
        case secretIrrecoverable
    }

    func getShares(participants: [BigInt], threshold: Int, secret: BigInt) throws -> [Point] {
        guard threshold <= participants.count else {
            throw ShareError.secretIrrecoverable
        }

        var vec = Vector(repeating: .zero, count: threshold)

        for i in 0..<vec.count {
            if i == 0 {
                vec[i] = secret
            } else {
                vec[i] = SecretSharerUtils.randomFieldElement(order: order)
            }
        }

        let rowShares = dotProduct(matrix: vandermonde(participants: participants, threshold: threshold), vector: vec)

        return participants.enumerated().map { i, p in
            Point(x: p, y: rowShares[i])
        }
    }

    func getReshares(newParticipants: [BigInt], newThreshold: Int) throws -> [[Point]] {
        // generate the reshares from the first threshold participants
        try participants.prefix(threshold).indices.map { i in
            try getShares(participants: newParticipants, threshold: newThreshold, secret: shards[i].y)
        }
    }
}

