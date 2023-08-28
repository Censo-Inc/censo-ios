//
//  Models.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-18.
//

import Foundation

extension API {
    struct User: Decodable {
        var name: String
        var contacts: [Contact]
    }

    struct Contact: Decodable {
        enum `Type`: String, Decodable {
            case email = "Email"
            case phone = "Phone"
        }

        var identifier: String
        var contactType: `Type`
        var value: String
        var verified: Bool
    }
}
