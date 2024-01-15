//
//  UserCredentials.swift
//  Censo
//
//  Created by Ata Namvari on 2023-09-18.
//

import Foundation
import CryptoKit

struct UserCredentials: Codable, Equatable {
    var idToken: Data
    var userIdentifier: String

    enum CodingKeys: String, CodingKey {
        case idToken = "jwtToken"
        case userIdentifier = "identityToken"
    }
    
    func userIdentifierHash() -> String {
        return Data(SHA256.hash(
            data: Data(userIdentifier.data(using: .utf8)!)
        )).toHexString()
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
    
    static func removeUserCredentials() {
        clear(account: userCredentialsService, service: userCredentialsService)
    }
}
