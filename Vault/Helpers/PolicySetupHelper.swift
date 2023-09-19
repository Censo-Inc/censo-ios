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
    var shards: [Point]
    var masterEncryptionPublicKey: Base58EncodedPublicKey
    var encryptedMasterPrivateKey: Base64EncodedString
    var intermediatePublicKey: Base58EncodedPublicKey
    var guardians: [API.Guardian] = []


    init(
        threshold: Int,
        guardians: [(ParticipantId, Base58EncodedPublicKey)]
    ) throws {
        let masterEncryptionKey = try EncryptionKey.generateRandomKey()
        masterEncryptionPublicKey = try masterEncryptionKey.publicExternalRepresentation()
        let intermediateEncryptionKey = try EncryptionKey.generateRandomKey()
        intermediatePublicKey = try intermediateEncryptionKey.publicExternalRepresentation()
        encryptedMasterPrivateKey = try intermediateEncryptionKey.encrypt(data: masterEncryptionKey.privateKeyRaw())
        let sharer = try SecretSharer(
            secret: BigInt(intermediateEncryptionKey.privateKeyRaw().toHexString(), radix: 16)!,
            threshold: threshold,
            participants: guardians.map({$0.0.bigInt})
        )
        self.shards = sharer.shards
        self.guardians = try guardians.map({
            API.Guardian(
                participantId: $0.0,
                encryptedShard: try getEncryptedShard(participantId: $0.0.bigInt, guardianPublicKey: $0.1)
            )
        })
    }
    
    private func getEncryptedShard(participantId: BigInt, guardianPublicKey: Base58EncodedPublicKey) throws -> Base64EncodedString {
        guard let shard = self.shards.first(where: {$0.x == participantId}) else {
            throw PolicySetupError.badParticipantId
        }
        return try EncryptionKey.generateFromPublicExternalRepresentation(base58PublicKey: guardianPublicKey).encrypt(data: shard.y.magnitude.serialize())
    }
}
