//
//  Guardianship.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-23.
//

import Foundation

struct Guardianship: Codable {
    //let intermediateKey: SecKey
    let threshold: Int
    //var guardians: [Guardian]
    //var coefficients: [BigInt]
}

class GuardianshipStorage: ObservableObject {
    private var guardianShip: Guardianship

    init(guardianShip: Guardianship) {
        self.guardianShip = guardianShip
    }
}
