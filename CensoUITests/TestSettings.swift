//
//  TestSettings.swift
//  CensoUITests
//
//  Created by Brendan Flood on 1/29/24.
//

import XCTest
import Foundation
import DeviceCheck

enum PhraseLanguage {
    case english
    case french
    case japanese
}
class TestSettings {
    static let shared = TestSettings()
    var app: XCUIApplication!
    var springboardApp: XCUIApplication!
    var password: String? = nil
    var isSimulator: Bool = false
    var firstPhraseLabel: String = "FirstPhrase"
    var userIdentifier: String = "testAppleUserIdentifier-\(UUID().uuidString)"
    var currentLanguage = PhraseLanguage.english
    let wordMap: [PhraseLanguage: [String]] = [
        .english: ["uncle", "bar", "tissue", "bus", "cabin", "segment", "miss", "staff", "wise", "country", "ranch", "ketchup"],
        .french: ["tonique", "article", "strict", "blanchir", "bobine", "protéger", "libre", "rustique", "visuel", "cigare", "panorama", "hésiter"],
        .japanese: ["めだつ", "うえる", "まんが", "おうえん", "おうよう", "はちみつ", "たよる", "ふせぐ", "れんさい", "きけんせい", "にっき", "せんぞ"]
    ]
    
    let languageButtonIdentifier: [PhraseLanguage: String] = [
        .japanese: "日本語\nJapanese",
        .french: "Français\nFrench",
        .english: "English\nEnglish"
    ]
    
    private init() {
        app = XCUIApplication()
        app.launchArguments = ["testing", "\(words().joined(separator: " "))", userIdentifier]
        app.launch()
        springboardApp = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        isSimulator = !DCAppAttestService().isSupported
    }
    
    func restartApp(language: PhraseLanguage = .english, newUser: Bool = false, clipboardData: String? = nil) -> XCUIApplication {
        currentLanguage = language
        if newUser {
            userIdentifier = "testAppleUserIdentifier-\(UUID().uuidString)"
        }
        app.launchArguments = ["testing", clipboardData ?? "\(words().joined(separator: " "))", userIdentifier]
        app.launch()
        return app
    }
    
    func words(language: PhraseLanguage? = nil) -> [String] {
        return wordMap[language ?? currentLanguage]!
    }
    
}
