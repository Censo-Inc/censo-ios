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
        let deviceKey = DeviceKey.sample
        let guardians = [
            GuardianProspect(label: "Guardian 1", participantId: generatePartitionId()),
            GuardianProspect(label: "Guardian 2", participantId: generatePartitionId()),
            GuardianProspect(label: "Guardian 2", participantId: generatePartitionId())
        ]
        let policySetupHelper = try PolicySetupHelper(threshold: 2, guardians: guardians, deviceKey: deviceKey)
        
        // encrypt some data with master key so we test recovery
        let seedPhrase = "Seed Phrase"
        let encryptedSeedPhrase = try EncryptionKey.generateFromPublicExternalRepresentation(
            base58PublicKey: policySetupHelper.masterEncryptionPublicKey
        ).encrypt(data: Data(seedPhrase.utf8))
        
        // recover the intermediate key from shards
        let recoveredIntermediatePrivateKeyData = try SecretSharerUtils.recoverSecret(
            shares: [
                getPoint(policySetupHelper, 0, deviceKey),
                getPoint(policySetupHelper, 1, deviceKey),
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
                data: Data(base64Encoded: policySetupHelper.encryptedMasterPrivateKey)!
            )
        )
        XCTAssertEqual(
            policySetupHelper.masterEncryptionPublicKey,
            try recoveredMasterPrivateKey.publicExternalRepresentation()
        )
        
        // make sure we can decrypt with recovered master and get back original data
        XCTAssertEqual(
            String(decoding: try recoveredMasterPrivateKey.decrypt(data: encryptedSeedPhrase), as: UTF8.self),
            seedPhrase
        )
    }
    
    func getPoint(_ policySetupHelper: PolicySetupHelper, _ index: Int, _ deviceKey: DeviceKey) throws -> Point {
        var error: Unmanaged<CFError>?
        let data = SecKeyCopyExternalRepresentation(deviceKey.secKey, &error) as Data?
        guard data != nil else {
            throw error!.takeRetainedValue() as Error
        }
        let devicePrivateKey = try EncryptionKey.generateFromPrivateKeyX963(data: data!)
        let guardianInvite = policySetupHelper.guardianInvites[index]
        
        let decryptedData = try devicePrivateKey.decrypt(data: Data(base64Encoded: guardianInvite.encryptedShard)!).toHexString()
        return Point(x: BigInt(guardianInvite.participantId, radix: 16)!, y: BigInt(decryptedData, radix: 16)!)
    }
}
