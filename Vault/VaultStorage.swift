//
//  VaultStorage.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-09.
//

import Foundation
import BIP39

enum VaultEntryError: Error {
    case nameExists
    case invalidPhrase(Error)
}

enum VaultReadError: Error {
    case nameNotFound
}

class VaultStorage: ObservableObject {
    var names: [String] {
        Array(vault.entries.keys.sorted())
    }

    private var vault: Vault
    private var deviceKey: DeviceKey

    init(vault: Vault, deviceKey: DeviceKey) {
        self.vault = vault
        self.deviceKey = deviceKey
    }

    func phrase(for name: String) -> Phrase? {
        vault.entries[name]
    }

    func insertPhrase(withName name: String, words: String) throws {
        guard phrase(for: name) == nil else {
            throw VaultEntryError.nameExists
        }

        let tokens = words.lowercased().split(separator: " ").map(String.init)

        do {
            _ = try Mnemonic(phrase: tokens)
        } catch {
            throw VaultEntryError.invalidPhrase(error)
        }

        let encryptedWords = try deviceKey.encrypt(data: words.data(using: .utf8)!)
        let phrase = Phrase(createdAt: Date(), encryptedWords: encryptedWords)

        var vault = self.vault
        vault.entries[name] = phrase

        let vaultData = try JSONEncoder().encode(vault)
        let encryptedVault = try deviceKey.encrypt(data: vaultData)

        try Keychain.saveEncryptedVault(encryptedVault)

        objectWillChange.send()
        self.vault = vault
    }

    func decodedPhrase(name: String, completion: @escaping (Result<DecodedPhrase, Error>) -> Void) {
        guard let phrase = vault.entries[name] else {
            completion(.failure(VaultReadError.nameNotFound))
            return
        }

        deviceKey.preauthenticatedKey { result in
            switch result {
            case .success(let preauthenticatedKey):
                do {
                    let decodedData = try preauthenticatedKey.decrypt(data: phrase.encryptedWords)
                    let decodedString = String(data: decodedData, encoding: .utf8) ?? ""
                    let words = decodedString.lowercased().split(separator: " ").map(String.init)
                    let decodedPhrase = DecodedPhrase(name: name, createdAt: phrase.createdAt, words: words)
                    completion(.success(decodedPhrase))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
