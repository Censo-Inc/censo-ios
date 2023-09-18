//
//  SecureEnclaveWrapper.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-09.
//

import Foundation
import Security
import LocalAuthentication

struct SecureEnclaveWrapper {
    static func loadKey(name: String, authenticationContext: LAContext?) -> SecKey? {
        let tag = name.data(using: .utf8)!
        var query: [String: Any] = [
            kSecClass as String                 : kSecClassKey,
            kSecAttrApplicationTag as String    : tag,
            kSecAttrKeyType as String           : kSecAttrKeyTypeEC,
            kSecReturnRef as String             : true
        ]

        if let authenticationContext = authenticationContext {
            query[kSecUseAuthenticationContext as String] = authenticationContext
        }

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            return nil
        }
        return (item as! SecKey)
    }

    static var accessControl: SecAccessControl {
        SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                        kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                                        [.privateKeyUsage],
                                        nil)!
    }

    static func makeAndStoreKey(name: String, authenticationContext: LAContext?) throws -> SecKey {
        removeKey(name: name)

        let tag = name.data(using: .utf8)!
        var attributes: [String: Any] = [
            kSecAttrKeyType as String           : kSecAttrKeyTypeEC,
            kSecAttrKeySizeInBits as String     : 256,
            kSecAttrTokenID as String           : kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String : [
                kSecAttrIsPermanent as String       : true,
                kSecAttrApplicationTag as String    : tag,
                kSecAttrAccessControl as String     : accessControl
            ] as [String : Any]
        ]

        if let authenticationContext = authenticationContext {
            attributes[kSecUseAuthenticationContext as String] = authenticationContext
        }

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw error!.takeRetainedValue() as Error
        }

        return privateKey
    }

    static func removeKey(name: String) {
        let tag = name.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String                 : kSecClassKey,
            kSecAttrApplicationTag as String    : tag
        ]

        SecItemDelete(query as CFDictionary)
    }
}
