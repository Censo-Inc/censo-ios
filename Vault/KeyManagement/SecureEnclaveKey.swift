//
//  SecureEnclaveKey.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-09.
//

import Foundation
import LocalAuthentication

protocol SecureEnclaveKey {
    var identifier: String { get }
    var secKey: SecKey { get }
}

enum SecKeyError: Error {
    case invalidKey
    case algorithmNotSupported
}

extension SecureEnclaveKey {
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
}

extension SecureEnclaveKey {
    public func publicExternalRepresentation() throws -> Data {
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
}
