//
//  EncryptionKey.swift
//  Censo
//
//  Created by Brendan Flood on 9/5/23.
//

import Foundation
import CryptoKit
import BigInt

struct EncryptionKey : SigningKey {
    var secKey: SecKey
    
    fileprivate init(secKey: SecKey) {
        self.secKey = secKey
    }
    
    public func publicKeyData() throws -> Data {
        guard let publicKey = SecKeyCopyPublicKey(secKey) else {
            throw SecKeyError.invalidKey
        }

        var error: Unmanaged<CFError>?
        let data = SecKeyCopyExternalRepresentation(publicKey, &error) as Data?
        guard data != nil else {
            throw error!.takeRetainedValue() as Error
        }
        
        return data!
    }
    
    public func publicExternalRepresentation() throws -> Base58EncodedPublicKey {
        return try Base58EncodedPublicKey(data: try publicKeyData())
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
    
    public func encrypt(data: Data) throws -> Base64EncodedString {
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

        return Base64EncodedString(data: encryptedData!)
    }

    public func decrypt(base64EncodedString: Base64EncodedString) throws -> Data {
        let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorVariableIVX963SHA256AESGCM

        guard SecKeyIsAlgorithmSupported(secKey, .decrypt, algorithm) else {
            throw SecKeyError.algorithmNotSupported
        }


        var error: Unmanaged<CFError>?
        let decryptedData = SecKeyCreateDecryptedData(secKey,
                                                      algorithm,
                                                      base64EncodedString.data as CFData,
                                                      &error) as Data?

        guard decryptedData != nil else {
            throw error!.takeRetainedValue() as Error
        }

        return decryptedData!
    }
    
    func signature(for data: Data) throws -> Base64EncodedString {
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

        return Base64EncodedString(data: signature!)
    }
    
    func verifySignature(for data: Data, signature: Base64EncodedString) throws -> Bool {
        let algorithm: SecKeyAlgorithm = .ecdsaSignatureMessageX962SHA256

        guard let publicKey = SecKeyCopyPublicKey(secKey) else {
            throw SecKeyError.invalidKey
        }


        var error: Unmanaged<CFError>?
        return SecKeyVerifySignature(publicKey, algorithm,
                                     data as CFData,
                                     signature.data as CFData,
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
        ] as NSDictionary, &error)
        guard privateKey != nil else {
            throw error!.takeRetainedValue() as Error
        }
        return EncryptionKey(secKey: privateKey!)
    }
    
    static func generateFromPublicExternalRepresentation(base58PublicKey: Base58EncodedPublicKey) throws -> EncryptionKey {
        var error: Unmanaged<CFError>?
        let publicKey = SecKeyCreateWithData(base58PublicKey.data as NSData, [
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass: kSecAttrKeyClassPublic,
        ] as NSDictionary, &error)
        guard publicKey != nil else {
            throw error!.takeRetainedValue() as Error
        }
        return EncryptionKey(secKey: publicKey!)
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
