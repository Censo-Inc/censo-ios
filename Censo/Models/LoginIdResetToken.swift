//
//  LoginIdResetToken.swift
//  Censo
//
//  Created by Anton Onyshchenko on 08.01.24.
//

import Foundation

struct LoginIdResetToken: Equatable, Hashable, Codable {
    var value: String
    
    static func fromURL(_ url: URL) throws -> LoginIdResetToken {
        guard let scheme = url.scheme,
              scheme.starts(with: "censo-main"),
              url.host == "reset",
              url.pathComponents.count == 2 else {
            throw CensoError.invalidUrl(url: "\(url)")
        }
        
        return LoginIdResetToken(value: url.pathComponents[1])
    }
    
    init(value: String) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self = LoginIdResetToken(value: try container.decode(String.self))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

#if DEBUG
extension LoginIdResetToken {
    static var sample: LoginIdResetToken {
        return LoginIdResetToken(value: "123")
    }
}
#endif
