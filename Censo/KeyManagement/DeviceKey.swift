//
//  DeviceKey.swift
//  Censo
//
//  Created by Ata Namvari on 2023-08-09.
//

import Foundation
import Security
import LocalAuthentication

struct DeviceKey: SecureEnclaveKey, Equatable {
    let identifier: String
    let secKey: SecKey

    fileprivate init(identifier: String, secKey: SecKey) {
        self.secKey = secKey
        self.identifier = identifier
    }
}

extension SecureEnclaveWrapper {
    static func deviceKeyIdentifier(userIdentifier: String) -> String {
        return "deviceKey-\(userIdentifier)"
    }

    static func deviceKey(userIdentifier: String) -> DeviceKey? {
        guard let secKey = loadKey(name: deviceKeyIdentifier(userIdentifier: userIdentifier), authenticationContext: nil) else {
            return nil
        }

        return DeviceKey(identifier: deviceKeyIdentifier(userIdentifier: userIdentifier), secKey: secKey)
    }

    static func generateDeviceKey(userIdentifier: String) throws -> DeviceKey {
        if let deviceKey = deviceKey(userIdentifier: userIdentifier) {
            return deviceKey
        } else {
            let secKey = try makeAndStoreKey(name: deviceKeyIdentifier(userIdentifier: userIdentifier), authenticationContext: nil)
            return DeviceKey(identifier: deviceKeyIdentifier(userIdentifier: userIdentifier), secKey: secKey)
        }
    }

    static func removeDeviceKey(for userIdentifier: String) {
        SecureEnclaveWrapper.removeKey(name: deviceKeyIdentifier(userIdentifier: userIdentifier))
    }
}

#if DEBUG
extension DeviceKey {
    static var sample: DeviceKey {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String           : kSecAttrKeyTypeEC,
            kSecAttrKeySizeInBits as String     : 256,
            kSecPrivateKeyAttrs as String : [
                kSecAttrIsPermanent as String       : true,
                kSecAttrApplicationTag as String    : "test"
            ] as [String : Any]
        ]

        var error: Unmanaged<CFError>?
        let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error)!

        return DeviceKey(identifier: "test", secKey: privateKey)
    }
}
#endif
