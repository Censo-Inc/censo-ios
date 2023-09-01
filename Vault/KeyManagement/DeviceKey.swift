//
//  DeviceKey.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-09.
//

import Foundation
import Security
import LocalAuthentication

struct DeviceKey: SecureEnclaveKey {
    let identifier: String
    let secKey: SecKey

    fileprivate init(identifier: String, secKey: SecKey) {
        self.secKey = secKey
        self.identifier = identifier
    }
}

extension SecureEnclaveWrapper {
    static func deviceKeyIdentifier() -> String {
        return "deviceKey"
    }

    static func deviceKey(authenticationContext: LAContext? = nil) -> DeviceKey? {
        guard let secKey = loadKey(name: deviceKeyIdentifier(), authenticationContext: authenticationContext) else {
            return nil
        }

        return DeviceKey(identifier: deviceKeyIdentifier(), secKey: secKey)
    }

    static func generateDeviceKey(authenticationContext: LAContext? = nil) throws -> DeviceKey {
        if let deviceKey = deviceKey(authenticationContext: authenticationContext) {
            return deviceKey
        } else {
            let secKey = try makeAndStoreKey(name: deviceKeyIdentifier(), authenticationContext: authenticationContext)
            return DeviceKey(identifier: deviceKeyIdentifier(), secKey: secKey)
        }
    }

    static func removeDeviceKey() throws {
        SecureEnclaveWrapper.removeKey(name: deviceKeyIdentifier())
    }
}

extension DeviceKey {
    enum DeviceKeyError: Error {
        case keyInvalidatedByBiometryChange
    }

    func preauthenticatedKey(_ completion: @escaping (Result<PreauthenticatedKey<DeviceKey>, Error>) -> Void) {
        #if DEBUG
        if CommandLine.isTesting {
            completion(.success(try! self.preauthenticatedKey(context: LAContext())))
            return
        }
        #endif

        let context = LAContext()
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Identify Yourself") { success, error in
            if let error = error {
                // not authenticated
                completion(.failure(error))
            } else {
                do {
                    let preauthenticatedKey = try self.preauthenticatedKey(context: context)
                    let timestamp = Date()
                    let signature = try preauthenticatedKey.signature(for: timestamp.ISO8601Format().data(using: .utf8)!)
                    let deviceKeyTimestamp = DeviceKeyTimestamp(timestamp: timestamp, signature: signature)

                    try? Keychain.saveDeviceKeyTimestamp(deviceKeyTimestamp)

                    completion(.success(preauthenticatedKey))
                } catch (let error as NSError) where error._domain == "CryptoTokenKit" && error._code == -3 {
                    // key no longer valid

                    completion(.failure(DeviceKeyError.keyInvalidatedByBiometryChange))
                } catch {
                    // other error
                    print(error)
                    completion(.failure(error))
                }
            }
        }
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
