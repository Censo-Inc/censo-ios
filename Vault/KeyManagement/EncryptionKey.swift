//
//  EncryptionKey.swift
//  Vault
//
//  Created by Brendan Flood on 9/5/23.
//

import Foundation
import CryptoKit

struct EncryptionKey {
    var secKey: SecKey
    
    fileprivate init(secKey: SecKey) {
        self.secKey = secKey
    }
    
    public func publicExternalRepresentation() throws -> String {
        guard let publicKey = SecKeyCopyPublicKey(secKey) else {
            throw SecKeyError.invalidKey
        }

        var error: Unmanaged<CFError>?
        let data = SecKeyCopyExternalRepresentation(publicKey, &error) as Data?
        guard data != nil else {
            throw error!.takeRetainedValue() as Error
        }

        return Base58.encode([UInt8](data!))
    }
    
    public func privateKeyX963() throws -> Data {

        var error: Unmanaged<CFError>?
        let data = SecKeyCopyExternalRepresentation(secKey, &error) as Data?
        guard data != nil else {
            throw error!.takeRetainedValue() as Error
        }

        return data!
    }
    
    public func privateKeyRaw() throws -> Data {
        return try P256.Signing.PrivateKey.init(x963Representation: privateKeyX963()).rawRepresentation
    }
    
    public func encrypt(data: Data) throws -> Data {
        guard let publicKey = SecKeyCopyPublicKey(secKey) else {
            throw SecKeyError.invalidKey
        }

        let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorVariableIVX963SHA256AESGCM

        guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, algorithm) else {
            throw SecKeyError.algorithmNotSupported
        }

        var error: Unmanaged<CFError>?
        let encryptedData = SecKeyCreateEncryptedData(publicKey, algorithm,
                                                   data as CFData,
                                                   &error) as Data?
        guard encryptedData != nil else {
            throw error!.takeRetainedValue() as Error
        }

        return encryptedData!
    }

    public func decrypt(data: Data) throws -> Data {
        let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorVariableIVX963SHA256AESGCM

        guard SecKeyIsAlgorithmSupported(secKey, .decrypt, algorithm) else {
            throw SecKeyError.algorithmNotSupported
        }


        var error: Unmanaged<CFError>?
        let decryptedData = SecKeyCreateDecryptedData(secKey,
                                                      algorithm,
                                                      data as CFData,
                                                      &error) as Data?

        guard decryptedData != nil else {
            throw error!.takeRetainedValue() as Error
        }

        return decryptedData!
    }
    
    func signature(for data: Data) throws -> Data {
        let algorithm: SecKeyAlgorithm = .ecdsaSignatureMessageX962SHA256

        guard SecKeyIsAlgorithmSupported(secKey, .sign, algorithm) else {
            throw SecKeyError.algorithmNotSupported
        }


        var error: Unmanaged<CFError>?
        let signature = SecKeyCreateSignature(secKey, algorithm,
                                          data as CFData,
                                          &error) as Data?

        guard signature != nil else {
            throw error!.takeRetainedValue() as Error
        }

        return signature!
    }
    
    func verifySignature(for data: Data, signature: Data) throws -> Bool {
        let algorithm: SecKeyAlgorithm = .ecdsaSignatureMessageX962SHA256

        guard let publicKey = SecKeyCopyPublicKey(secKey) else {
            throw SecKeyError.invalidKey
        }


        var error: Unmanaged<CFError>?
        return SecKeyVerifySignature(publicKey, algorithm,
                                     data as CFData,
                                     signature as CFData,
                                     &error)
    }
    
    static func generateFromPrivateKeyRaw(data: Data) throws -> EncryptionKey {
        return try generateFromPrivateKeyX963(data: P256.Signing.PrivateKey.init(rawRepresentation: data).x963Representation)
    }
    
    static func generateFromPrivateKeyX963(data: Data) throws -> EncryptionKey {
        var error: Unmanaged<CFError>?
        let privateKey = SecKeyCreateWithData(data as NSData, [
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass: kSecAttrKeyClassPrivate,
        ] as NSDictionary, nil)
        guard privateKey != nil else {
            throw error!.takeRetainedValue() as Error
        }
        return EncryptionKey(secKey: privateKey!)
    }
    
    static func generateFromPublicExternalRepresentation(base58PublicKey: Base58EncodedPublicKey) throws -> EncryptionKey {
        var error: Unmanaged<CFError>?
        let privateKey = SecKeyCreateWithData(Data(Base58.decode(base58PublicKey)) as NSData, [
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass: kSecAttrKeyClassPublic,
        ] as NSDictionary, nil)
        guard privateKey != nil else {
            throw error!.takeRetainedValue() as Error
        }
        return EncryptionKey(secKey: privateKey!)
    }
    
    static func generateRandomKey() throws -> EncryptionKey {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String           : kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String     : 256,
        ]

        var error: Unmanaged<CFError>?
        let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error)!

        return EncryptionKey(secKey: privateKey)
    }
}
