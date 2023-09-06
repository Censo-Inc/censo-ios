//
//  PolicySetupHelper.swift
//  Vault
//
//  Created by Brendan Flood on 9/6/23.
//

import Foundation
import BigInt

struct PolicySetupHelper {
    var shards: [Point]
    var masterEncryptionPublicKey: Base58EncodedPublicKey
    var encryptedMasterPrivateKey: Base64EncodedData
    var intermediatePublicKey: Base58EncodedPublicKey
    var guardianInvites: [API.GuardianInvite] = []
    var deviceKey: DeviceKey
    
    enum PolicySetupError: Error {
        case badParticipantId
    }

    init(
        threshold: Int,
        guardians: [GuardianProspect],
        deviceKey: DeviceKey
    ) throws {
        let masterEncryptionKey = try EncryptionKey.generateRandomKey()
        masterEncryptionPublicKey = try masterEncryptionKey.publicExternalRepresentation()
        let intermediateEncryptionKey = try EncryptionKey.generateRandomKey()
        intermediatePublicKey = try intermediateEncryptionKey.publicExternalRepresentation()
        encryptedMasterPrivateKey = try intermediateEncryptionKey.encrypt(data: masterEncryptionKey.privateKeyRaw()).base64EncodedString()
        let sharer = try SecretSharer(
            secret: BigInt(intermediateEncryptionKey.privateKeyRaw().toHexString(), radix: 16)!,
            threshold: threshold,
            participants: guardians.map({$0.participantId})
        )
        self.shards = sharer.shards
        self.deviceKey = deviceKey
        self.guardianInvites = try guardians.map({
            API.GuardianInvite(
                name: $0.label,
                participantId: $0.participantId.magnitude.to32PaddedHexString(),
                encryptedShard: try getEncryptedShard(participant: $0.participantId).base64EncodedString()
            )
        })
    }
    
    private func getEncryptedShard(participant: BigInt) throws -> Data {
        guard let shard = self.shards.first(where: {$0.x == participant}) else {
            throw PolicySetupError.badParticipantId
        }
        return try deviceKey.encrypt(data: shard.y.magnitude.serialize())
    }
}
