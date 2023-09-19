//
//  Keychain+UserIdentifier.swift
//  Vault
//
//  Created by Ata Namvari on 2023-09-18.
//

import Foundation

extension Keychain {
    static let userIdentifierService = "co.censo.userIdentifierService"

    static var userIdentifier: String? {
        get {
            let data = try? load(account: userIdentifierService, service: userIdentifierService)
            return data.flatMap {
                String(data: $0, encoding: .utf8)
            }
        }
        set {
            newValue?
                .data(using: .utf8)
                .flatMap {
                    try? save(account: userIdentifierService, service: userIdentifierService, data: $0)
                }
        }
    }
}
