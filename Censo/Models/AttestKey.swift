//
//  AttestKey.swift
//  Censo
//
//  Created by Ata Namvari on 2023-11-16.
//

import Foundation

struct AttestKey: Codable {
    var keyId: String
    var verified: Bool

    init(keyId: String) {
        self.keyId = keyId
        self.verified = false
    }

    enum CodingKeys: String, CodingKey {
        case keyId
        case verified
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(keyId, forKey: .keyId)
        try container.encode(verified, forKey: .verified)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.keyId = try container.decode(String.self, forKey: .keyId)
        self.verified = try container.decode(Bool.self, forKey: .verified)
    }
}

extension AttestKey: RawRepresentable {
    init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
            let result = try? JSONDecoder().decode(Self.self, from: data)
        else {
            return nil
        }
        self = result
    }

    var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
            let result = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return result
    }
}
