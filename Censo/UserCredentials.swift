//
//  UserCredentials.swift
//  Censo
//
//  Created by Ata Namvari on 2023-09-18.
//

import Foundation

struct UserCredentials: Codable {
    var idToken: Data
    var userIdentifier: String

    enum CodingKeys: String, CodingKey {
        case idToken = "jwtToken"
        case userIdentifier = "identityToken"
    }
}

extension Keychain {
    static let userCredentialsService = "co.censo.userCredentialsService"

    static var userCredentials: UserCredentials? {
        get {
            try? load(account: userCredentialsService, service: userCredentialsService)
                .flatMap {
                    try? JSONDecoder().decode(UserCredentials.self, from: $0)
                }
        }
        set {
            newValue
                .flatMap {
                    try? JSONEncoder().encode($0)
                }
                .flatMap {
                    try? save(account: userCredentialsService, service: userCredentialsService, data: $0)
                }
        }
    }
}
