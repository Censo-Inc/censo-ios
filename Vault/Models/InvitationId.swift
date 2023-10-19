//
//  InvitationId.swift
//  Vault
//
//  Created by Brendan Flood on 10/19/23.
//

import Foundation

struct InvitationId: Codable, Equatable, Hashable {
    var value: String
    var url: URL
    
    init(value: String) throws {
        guard let url = URL(string: "censo-guardian://invite/\(value)") else {
            throw ValueWrapperError.invalidInvitationId
        }
        self.value = value
        self.url = url
    }
    
    init(from decoder: Decoder) throws {
        var container = try decoder.singleValueContainer()
        do {
            self = try InvitationId(value: try container.decode(String.self))
        } catch {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid InvitationId")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
    
}
