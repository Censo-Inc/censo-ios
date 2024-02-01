//
//  TestHelper.swift
//  CensoUITests
//
//  Created by Brendan Flood on 1/30/24.
//

import Foundation
import XCTest

class TestHelper {
    static let app = TestSettings.shared.app!
    
    static func onboard(phraseInputButton: String) {
        
        acceptTermsAndConditions()

        app.waitForButtonAndTap(buttonIdentifier: "getStarted")
        
        if let password = TestSettings.shared.password {
            let passwordLink = app.staticTexts["usePasswordLink"]
            XCTAssertTrue(passwordLink.waitForExistence(timeout: 5))
            passwordLink.tap()
            
            app.enterSecureText(fieldIdentifier: "passwordField", secureText: password, enterReturn: false)
            app.enterSecureText(fieldIdentifier: "passwordConfirmField", secureText: password, enterReturn: true)
            
            app.waitForButtonAndTap(buttonIdentifier: "createPasswordButton")
        } else {
            app.waitForButtonAndTap(buttonIdentifier: "beginFaceSanButton")
        }

        addPhrase(inputButton: phraseInputButton, label: TestSettings.shared.firstPhraseLabel, expectPaywall: false, onboarding: true)
        
        app.waitForButtonAndTap(buttonIdentifier: "noThanksButton")
        
        app.waitForButtonAndTap(buttonIdentifier: "Home")
        XCTAssertTrue(app.buttons["Home"].isSelected)
        
        XCTAssertTrue(app.buttons["My Phrases"].exists)
        XCTAssertTrue(app.buttons["Settings"].exists)
    }
    
    static func addPhrase(inputButton: String, label: String, expectPaywall: Bool, onboarding: Bool) {
        
        if !onboarding {
            app.waitForButtonAndTap(buttonIdentifier: "Home")
            app.waitForButtonAndTap(buttonIdentifier: "addSeedPhraseButton")
        }
        
        TestHelper.selectAddPhraseOption(inputType: inputButton)
        
        switch inputButton {
        case "enterPhraseButton":
            app.waitForButtonAndTap(buttonIdentifier: "enterWordButton")
            
            let words = TestSettings.shared.words
            words.enumerated().forEach { (index, word) in
                app.enterText(fieldIdentifier: "wordEntryTextField", inputText: word)
                
                app.waitForButtonAndTap(buttonIdentifier: word)

                XCTAssertTrue(app.staticTexts["\(index+1) word\(index > 0 ? "s" : "") total"].exists)
                XCTAssertTrue(app.staticTexts[word].exists)
                XCTAssertTrue(app.staticTexts[TestHelper.getWordText(index: index + 1)].exists)
                
                if word == words.last {
                    app.waitForButtonAndTap(buttonIdentifier: "finishButton")
                } else {
                    app.waitForButtonAndTap(buttonIdentifier: "enterWordButton")
                }
            }
            reviewAndSaveSeedPhrase(label: label, expectPaywall: expectPaywall, numWords: words.count, expectedWords: words)
            
        case "pastePhraseButton":
            let words = TestSettings.shared.words
            
            // XCUIApplication framework does not handle paste alerts and the tap() of the button hangs for 60 seconds.
            // On returning we respond to the Allow Paste alert which makes the test continue
            app.waitForButtonAndTap(buttonIdentifier: "pasteFromClipboardButton")
            if TestSettings.shared.springboardApp.alerts.buttons["Allow Paste"].exists {
                TestSettings.shared.springboardApp.alerts.buttons["Allow Paste"].tap()
            }
            reviewAndSaveSeedPhrase(label: label, expectPaywall: expectPaywall, numWords: words.count, expectedWords: words)
            
        case "generatePhraseButton":
            app.waitForButtonAndTap(buttonIdentifier: "generateButton")
            reviewAndSaveSeedPhrase(label: label, expectPaywall: false, numWords: 24, expectedWords: nil)
            
        case "photoPhraseButton":
            
            app.waitForButtonAndTap(buttonIdentifier: "startPhoto")
            
            if TestSettings.shared.springboardApp.alerts.buttons["Allow"].exists {
                TestSettings.shared.springboardApp.alerts.buttons["Allow"].tap()
            }
            
            app.waitForButtonAndTap(buttonIdentifier: "takeAPhoto")
            
            if TestSettings.shared.springboardApp.alerts.buttons["Allow"].exists {
                TestSettings.shared.springboardApp.alerts.buttons["Allow"].tap()
                app.waitForButtonAndTap(buttonIdentifier: "takeAPhoto")
            }
            
            app.waitForButtonAndTap(buttonIdentifier: "usePhoto")
            
            reviewAndSaveSeedPhrase(label: label, expectPaywall: false, numWords: 0, expectedWords: nil)
            
        default:
            XCTFail("invalid button type")
        }
    }
    
    static func acceptTermsAndConditions() {
        app.waitForButtonAndTap(buttonIdentifier: "reviewTermsButton")

        let terms = app.webViews["termsWebView"]
        XCTAssertTrue(terms.waitForExistence(timeout: 5))

        app.waitForButtonAndTap(buttonIdentifier: "acceptTermsButton")
    }
    
    static func validateHomeScreen(numPhrases: Int, numApprovers: Int) {
        app.waitForButtonAndTap(buttonIdentifier: "Home")
        XCTAssertTrue(app.staticTexts["\(numPhrases == 1 ? "It is" : "They are") stored securely and accessible only to you."].exists)
        XCTAssertTrue(app.staticTexts["\(numPhrases)"].exists)
        XCTAssertTrue(app.staticTexts["You have"].exists)
        XCTAssertTrue(app.staticTexts["seed phrase\(numPhrases == 1 ? "" : "s")."].exists)
        if numApprovers == 0 {
            XCTAssertTrue(app.staticTexts["\nYou can increase security by adding approvers."].exists)
        }
    }
    
    static func validateMyPhrasesScreen(expectedPhraseLabels: [String]) {
        app.waitForButtonAndTap(buttonIdentifier: "My Phrases")
        expectedPhraseLabels.forEach { label in
            XCTAssertTrue(app.staticTexts[label].exists)
        }
    }
    
    static func reviewAndSaveSeedPhrase(label: String, expectPaywall: Bool, numWords: Int, expectedWords: [String]?) {
        if numWords > 0 {
            for index in 1...numWords {
                let word = app.staticTexts[getWordText(index: index)]
                XCTAssertTrue(word.waitForExistence(timeout: 5))
                if let expectedWords {
                    XCTAssertTrue(app.staticTexts[expectedWords[index - 1]].exists)
                }
                if index != numWords {
                    word.swipeLeft(velocity: .fast)
                }
            }
            
            app.waitForButtonAndTap(buttonIdentifier: "nextButton")
        }
        
        app.enterText(fieldIdentifier: "labelTextField", inputText: label)
        app.waitForButtonAndTap(buttonIdentifier: "saveButton")
        
        if expectPaywall {
            XCTAssertTrue(app.buttons["purchaseMonthlyButton"].waitForExistence(timeout: 5))
            app.waitForButtonAndTap(buttonIdentifier: "purchaseYearlyButton")
        }

        app.waitForButtonAndTap(buttonIdentifier: "okButton")
    }
    
    private static func getWordText(index: Int) -> String {
        switch index {
        case 1: return "1st word"
        case 2: return "2nd word"
        case 3: return "3rd word"
        case 21: return "21st word"
        case 22: return "22nd word"
        case 23: return "23rd word"
        default: return "\(index)th word"
        }
    }
    
    static func selectAddPhraseOption(inputType: String) {
        if inputType != "generatePhraseButton" {
            app.waitForButtonAndTap(buttonIdentifier: "haveMyOwnButton")
        }
        app.waitForButtonAndTap(buttonIdentifier: inputType)
    }
    
    static func dumpElement(_ element: XCUIElement) {
        print("buttons: \(element.buttons.debugDescription)")
        print("textFields: \(element.textFields.debugDescription)")
        print("staticTexts: \(element.staticTexts.debugDescription)")
        
    }
}
