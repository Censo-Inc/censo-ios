//
//  EncryptionKey+Owner.swift
//  Censo
//
//  Created by Anton Onyshchenko on 26.10.23.
//

import Foundation
import BigInt
import Sentry

extension EncryptionKey {
    enum ShardingError: Error {
        case badParticipantId
    }

    func shard(threshold: Int, participants: [(ParticipantId, Base58EncodedPublicKey)]) throws -> [API.ApproverShard] {
        let sharer = try SecretSharer(
            secret: BigInt(privateKeyRaw().toHexString(), radix: 16)!,
            threshold: threshold,
            participants: participants.map({$0.0.bigInt})
        )
        return try participants.map({ (participantId, participantPublicKey) in
            guard let shard = sharer.shards.first(where: {$0.x == participantId.bigInt}) else {
                throw ShardingError.badParticipantId
            }
            return API.ApproverShard(
                participantId: participantId,
                encryptedShard: try EncryptionKey
                    .generateFromPublicExternalRepresentation(base58PublicKey: participantPublicKey)
                    .encrypt(data: shard.y.magnitude.serialize())
            )
        })
    }
    
    static func recover(_ encryptedShards: [API.EncryptedShard], _ session: Session) throws -> EncryptionKey {
        let points = try encryptedShards.map { encryptedShard in
            let decryptedShard: Data
            
            if encryptedShard.isOwnerShard {
                guard let ownerApproverKey = encryptedShard.participantId.privateKey(userIdentifier: session.userCredentials.userIdentifier) else {
                    SentrySDK.captureWithTag(error: CensoError.failedToRetrieveApproverKey, tagValue: "Approver Key")
                    throw CensoError.failedToRetrieveApproverKey
                }
                decryptedShard = try ownerApproverKey.decrypt(base64EncodedString: encryptedShard.encryptedShard)
            } else {
                decryptedShard = try session.deviceKey.decrypt(data: encryptedShard.encryptedShard.data)
            }
            
            return Point(
                x: encryptedShard.participantId.bigInt,
                y: decryptedShard.toPositiveBigInt()
            )
        }
        
        return try EncryptionKey.generateFromPrivateKeyRaw(
            data: SecretSharerUtils.recoverSecret(shares: points).magnitude.serialize().padded(toByteCount: 32)
        )
    }
    
    static func fromEncryptedPrivateKey(_ base64EncodedString: Base64EncodedString, _ encryptionKey: EncryptionKey) throws -> EncryptionKey {
        return try EncryptionKey.generateFromPrivateKeyRaw(data: try encryptionKey.decrypt(base64EncodedString: base64EncodedString))
    }
}
