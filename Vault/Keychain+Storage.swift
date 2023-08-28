//
//  Keychain+Storage.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-09.
//

import Foundation

public extension Keychain {
    static private let vaultService = "co.censo.vault"

    static func encryptedVault() throws -> Data? {
        try load(account: vaultService, service: vaultService)
    }

    static func saveEncryptedVault(_ encryptedVault: Data) throws {
        try save(account: vaultService, service: vaultService, data: encryptedVault, biometryProtected: false)
    }

    static func removeVault() {
        clear(account: vaultService, service: vaultService)
    }
}

public extension Keychain {
    static private let guardianshipService = "co.censo.guardianship"

    static func encryptedGuardianShip() throws -> Data? {
        try load(account: guardianshipService, service: guardianshipService)
    }


}
