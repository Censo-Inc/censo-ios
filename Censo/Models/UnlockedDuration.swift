//
//  UnlockedDuration.swift
//  Censo
//
//  Created by Brendan Flood on 10/20/23.
//

import Foundation

struct UnlockedDuration: Codable, Equatable, Hashable {
    var timeInterval: TimeInterval
    var locksAt: Date
    
    init(value: UInt) {
        self.timeInterval = Double(value)
        self.locksAt = Date.now.addingTimeInterval(self.timeInterval)
    }
    
    init(from decoder: Decoder) throws {
        var container = try decoder.singleValueContainer()
        do {
            self = try UnlockedDuration(value: container.decode(UInt.self))
        } catch {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid UnlockedDuration")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(UInt(timeInterval))
    }
    
}
