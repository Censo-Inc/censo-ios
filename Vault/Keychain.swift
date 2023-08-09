//
//  Keychain.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-09.
//

import Foundation
import Security
import LocalAuthentication

public class Keychain {
    enum KeychainError: Error {
        case couldNotSave(OSStatus)
        case couldNotLoad(OSStatus)
    }

    private class func queryDictionary(account: String, service: String) -> [String : Any] {
        return [
            kSecClass as String : kSecClassGenericPassword,
            kSecAttrAccount as String : account,
            kSecAttrService as String : service
        ]
    }

    public class func save(account: String, service: String, data: Data, synced: Bool = false, biometryProtected: Bool = false) throws {
        var query = queryDictionary(account: account, service: service)
        query[kSecValueData as String] = data

        if synced {
            query[kSecAttrSynchronizable as String] = true
        }

        SecItemDelete(query as CFDictionary)

        if biometryProtected {
            query[kSecAttrAccessControl as String] = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, [.biometryCurrentSet], nil)
        }

        let result = SecItemAdd(query as CFDictionary, nil)

        if result != noErr {
            throw KeychainError.couldNotSave(result)
        }
    }

    public class func load(account: String, service: String, synced: Bool = false, biometryPrompt: String? = nil) throws -> Data? {
        var query = queryDictionary(account: account, service: service)
        query[kSecReturnData as String] = kCFBooleanTrue!
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecAttrSynchronizable as String] = synced

        if let prompt = biometryPrompt {
            let context = LAContext()
            context.localizedReason = prompt

            query[kSecUseAuthenticationContext as String] = context
            query[kSecAttrAccessControl as String] = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, [.biometryCurrentSet], nil)
        }

        var foundData: AnyObject? = nil
        let status = SecItemCopyMatching(query as CFDictionary, &foundData)

        if status == noErr {
            return foundData as! Data?
        } else if status == errSecItemNotFound {
            return nil
        } else {
            throw KeychainError.couldNotLoad(status)
        }
    }

    @discardableResult
    public class func clear(account: String, service: String, synced: Bool = false) -> Bool {
        var query = queryDictionary(account: account, service: service)

        if synced {
            query[kSecAttrSynchronizable as String] = true
        }

        let result = SecItemDelete(query as CFDictionary)
        return result == noErr
    }

    public class func contains(account: String, service: String) -> Bool {
        var query = queryDictionary(account: account, service: service)

        let context = LAContext()
        context.interactionNotAllowed = true

        query[kSecUseAuthenticationContext as String] = context

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        return status == errSecInteractionNotAllowed || status == noErr
    }
}
