//
//  TestSettings.swift
//  CensoUITests
//
//  Created by Brendan Flood on 1/29/24.
//

import XCTest
import Foundation
import DeviceCheck

class TestSettings {
    static let shared = TestSettings()
    var app: XCUIApplication!
    var springboardApp: XCUIApplication!
    var password: String? = nil
    var isSimulator: Bool = false
    var firstPhraseLabel: String = "FirstPhrase"
    let words = ["uncle", "bar", "tissue", "bus", "cabin", "segment", "miss", "staff", "wise", "country", "ranch", "ketchup"]
    
    private init() {
        app = XCUIApplication()
        app.launchArguments = ["testing", "\(words.joined(separator: " "))", "testAppleUserIdentifier-\(UUID().uuidString)"]
        app.launch()
        springboardApp = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        isSimulator = !DCAppAttestService().isSupported
    }
    
}
