//
//  BeneficiaryInvitationId.swift
//  Censo
//
//  Created by Brendan Flood on 2/5/24.
//

import Foundation

import Foundation

struct BeneficiaryInvitationId: Codable, Equatable, Hashable, KeyId {
    var value: String
    var url: URL
    
    init(value: String) throws {
        guard let url = URL(string: "\(Configuration.ownerUrlScheme)://beneficiary/\(value)") else {
            throw ValueWrapperError.invalidInvitationId
        }
        self.value = value
        self.url = url
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            self = try BeneficiaryInvitationId(value: try container.decode(String.self))
        } catch {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid InvitationId")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
    
    static func fromURL(_ url: URL) throws -> BeneficiaryInvitationId {
        guard let scheme = url.scheme,
              scheme.starts(with: "censo-main"),
              url.host == "beneficiary",
              url.pathComponents.count == 2 else {
            throw CensoError.invalidUrl(url: "\(url)")
        }
        
        return try BeneficiaryInvitationId(value: url.pathComponents[1])
    }
}
