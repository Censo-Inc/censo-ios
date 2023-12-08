//
//  EncryptionKeyShardingAndRecoveryTests.swift
//  CensoTests
//
//  Created by Brendan Flood on 9/6/23.
//

import XCTest
import BigInt
@testable import Censo

final class EncryptionKeyShardingAndRecoveryTests: XCTestCase {
    func testShardingAndRecovery() throws {
        for index in (0...1000) {
            print("index is \(index)")
            let participantEncryptionKeys = [
                try EncryptionKey.generateRandomKey(),
                try EncryptionKey.generateRandomKey(),
                try EncryptionKey.generateRandomKey()
            ]
            let participants = [
                (ParticipantId(bigInt: generateParticipantId()), try participantEncryptionKeys[0].publicExternalRepresentation()),
                (ParticipantId(bigInt: generateParticipantId()), try participantEncryptionKeys[1].publicExternalRepresentation()),
                (ParticipantId(bigInt: generateParticipantId()), try participantEncryptionKeys[2].publicExternalRepresentation())
            ]
            let masterEncryptionKey = try EncryptionKey.generateRandomKey()
            let masterEncryptionPublicKey = try masterEncryptionKey.publicExternalRepresentation()
            let intermediateEncryptionKey = try EncryptionKey.generateRandomKey()
            let intermediatePublicKey = try intermediateEncryptionKey.publicExternalRepresentation()
            let encryptedMasterPrivateKey = try intermediateEncryptionKey.encrypt(data: masterEncryptionKey.privateKeyRaw())
            let participantShards = try intermediateEncryptionKey.shard(threshold: 2, participants: participants)
            
            // encrypt some data with master key so we test recovery
            let seedPhrase = "Seed Phrase"
            let encryptedSeedPhrase = try EncryptionKey.generateFromPublicExternalRepresentation(
                base58PublicKey: masterEncryptionPublicKey
            ).encrypt(data: Data(seedPhrase.utf8))
            
            // recover the intermediate key from shards
            let recoveredIntermediatePrivateKeyData = try SecretSharerUtils.recoverSecret(
                shares: [
                    getPoint(participantShards, 0, participantEncryptionKeys[0]),
                    getPoint(participantShards, 1, participantEncryptionKeys[1]),
                ],
                order: ORDER
            )
            
            let recoveredIntermediatePrivateKey = try EncryptionKey.generateFromPrivateKeyRaw(data: recoveredIntermediatePrivateKeyData.magnitude.serialize().padded(toByteCount: 32))
            XCTAssertEqual(
                intermediatePublicKey,
                try recoveredIntermediatePrivateKey.publicExternalRepresentation()
            )
            // decrypt and recover the the master key
            let recoveredMasterPrivateKey = try EncryptionKey.generateFromPrivateKeyRaw(
                data: recoveredIntermediatePrivateKey.decrypt(
                    base64EncodedString: encryptedMasterPrivateKey
                )
            )
            XCTAssertEqual(
                masterEncryptionPublicKey,
                try recoveredMasterPrivateKey.publicExternalRepresentation()
            )
            
            // make sure we can decrypt with recovered master and get back original data
            XCTAssertEqual(
                String(decoding: try recoveredMasterPrivateKey.decrypt(base64EncodedString: encryptedSeedPhrase), as: UTF8.self),
                seedPhrase
            )
        }
    }
    
    func getPoint(_ shards: [API.ApproverShard], _ index: Int, _ participantKey: EncryptionKey) throws -> Point {
        let participantShard = shards[index]
        let decryptedData = try participantKey.decrypt(base64EncodedString: participantShard.encryptedShard).toHexString()
        return Point(x: participantShard.participantId.bigInt, y: BigInt(decryptedData, radix: 16)!)
    }
}
