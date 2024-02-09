//
//  FeatureFlagState.swift
//  Censo
//
//  Created by Brendan Flood on 2/6/24.
//

import Foundation

class FeatureFlagState: ObservableObject {
    static let shared = FeatureFlagState([])
    @Published var features: [String] = []
    
    init(_ features: [String]) {
        self.features = features
    }
    
    func legacyEnabled() -> Bool {
        self.features.contains("legacy")
    }
}
