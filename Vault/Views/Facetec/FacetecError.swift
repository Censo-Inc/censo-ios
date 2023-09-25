//
//  FacetecError.swift
//  Vault
//
//  Created by Brendan Flood on 9/21/23.
//

import Foundation

struct FacetecError: Error, Sendable {
    var status: FaceTecSDKStatus
}
