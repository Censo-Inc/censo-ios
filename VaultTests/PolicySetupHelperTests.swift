//
//  PolicySetupHelperTests.swift
//  VaultTests
//
//  Created by Brendan Flood on 9/6/23.
//

import XCTest
import BigInt
@testable import Vault

final class PolicySetupHelperTests: XCTestCase {
    
    func testPolicySetupAndRecovery() throws {
        let guardianEncryptionKeys = [
            try EncryptionKey.generateRandomKey(),
            try EncryptionKey.generateRandomKey(),
            try EncryptionKey.generateRandomKey()
        ]
        let guardians = [
            (ParticipantId(bigInt: generateParticipantId()), try guardianEncryptionKeys[0].publicExternalRepresentation()),
            (ParticipantId(bigInt: generateParticipantId()), try guardianEncryptionKeys[1].publicExternalRepresentation()),
            (ParticipantId(bigInt: generateParticipantId()), try guardianEncryptionKeys[2].publicExternalRepresentation())
        ]
        let policySetupHelper = try PolicySetupHelper(threshold: 2, guardians: guardians)

        // encrypt some data with master key so we test recovery
        let seedPhrase = "Seed Phrase"
        let encryptedSeedPhrase = try EncryptionKey.generateFromPublicExternalRepresentation(
            base58PublicKey: policySetupHelper.masterEncryptionPublicKey
        ).encrypt(data: Data(seedPhrase.utf8))

        // recover the intermediate key from shards
        let recoveredIntermediatePrivateKeyData = try SecretSharerUtils.recoverSecret(
            shares: [
                getPoint(policySetupHelper, 0, guardianEncryptionKeys[0]),
                getPoint(policySetupHelper, 1, guardianEncryptionKeys[1]),
            ],
            order: ORDER
        )

        let recoveredIntermediatePrivateKey = try EncryptionKey.generateFromPrivateKeyRaw(data: recoveredIntermediatePrivateKeyData.magnitude.serialize())
        XCTAssertEqual(
            policySetupHelper.intermediatePublicKey,
            try recoveredIntermediatePrivateKey.publicExternalRepresentation()
        )
        // decrypt and recover the the master key
        let recoveredMasterPrivateKey = try EncryptionKey.generateFromPrivateKeyRaw(
            data: recoveredIntermediatePrivateKey.decrypt(
                base64EncodedString: policySetupHelper.encryptedMasterPrivateKey
            )
        )
        XCTAssertEqual(
            policySetupHelper.masterEncryptionPublicKey,
            try recoveredMasterPrivateKey.publicExternalRepresentation()
        )

        // make sure we can decrypt with recovered master and get back original data
        XCTAssertEqual(
            String(decoding: try recoveredMasterPrivateKey.decrypt(base64EncodedString: encryptedSeedPhrase), as: UTF8.self),
            seedPhrase
        )
    }
    
    func getPoint(_ policySetupHelper: PolicySetupHelper, _ index: Int, _ guardianKey: EncryptionKey) throws -> Point {

        let guardian = policySetupHelper.guardians[index]
        let decryptedData = try guardianKey.decrypt(base64EncodedString: guardian.encryptedShard).toHexString()
        return Point(x: guardian.participantId.bigInt, y: BigInt(decryptedData, radix: 16)!)
    }
}
