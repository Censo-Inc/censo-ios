//
//  SigningKey.swift
//  Censo
//
//  Created by Anton Onyshchenko on 31.10.23.
//

import Foundation

protocol SigningKey {
    func signature(for data: Data) throws -> Base64EncodedString
}
