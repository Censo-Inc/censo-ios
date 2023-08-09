//
//  Phrase.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-09.
//

import Foundation

struct Phrase: Codable {
    var createdAt: Date
    var encryptedWords: Data
}
