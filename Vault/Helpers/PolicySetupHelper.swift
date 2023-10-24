//
//  PolicySetupHelper.swift
//  Vault
//
//  Created by Brendan Flood on 9/6/23.
//

import Foundation
import BigInt

enum PolicySetupError: Error {
    case badParticipantId
    case badGuardianSignature
    case shardEncryptionError
    case badPublicKey
    case cannotCreateTotpSecret
}

struct PolicySetupHelper {
    var masterEncryptionPublicKey: Base58EncodedPublicKey
    var encryptedMasterPrivateKey: Base64EncodedString
    var intermediatePublicKey: Base58EncodedPublicKey
    var guardians: [API.GuardianShard] = []

    init(
        threshold: Int,
        guardians: [(ParticipantId, Base58EncodedPublicKey)]
    ) throws {
        let masterEncryptionKey = try EncryptionKey.generateRandomKey()
        masterEncryptionPublicKey = try masterEncryptionKey.publicExternalRepresentation()
        let intermediateEncryptionKey = try EncryptionKey.generateRandomKey()
        intermediatePublicKey = try intermediateEncryptionKey.publicExternalRepresentation()
        encryptedMasterPrivateKey = try intermediateEncryptionKey.encrypt(data: masterEncryptionKey.privateKeyRaw())
        self.guardians = try generateShards(
            intermediateEncryptionKey: intermediateEncryptionKey,
            threshold: threshold,
            guardians: guardians
        )
    }
}

func generateShards(
    intermediateEncryptionKey: EncryptionKey,
    threshold: Int,
    guardians: [(ParticipantId, Base58EncodedPublicKey)]
) throws -> [API.GuardianShard] {
    let sharer = try SecretSharer(
        secret: BigInt(intermediateEncryptionKey.privateKeyRaw().toHexString(), radix: 16)!,
        threshold: threshold,
        participants: guardians.map({$0.0.bigInt})
    )
    return try guardians.map({ (guardianParticipantId, guardianPublicKey) in
        guard let shard = sharer.shards.first(where: {$0.x == guardianParticipantId.bigInt}) else {
            throw PolicySetupError.badParticipantId
        }
        return API.GuardianShard(
            participantId: guardianParticipantId,
            encryptedShard: try EncryptionKey
                .generateFromPublicExternalRepresentation(base58PublicKey: guardianPublicKey)
                .encrypt(data: shard.y.magnitude.serialize())
        )
    })
}
