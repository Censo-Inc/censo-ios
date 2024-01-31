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
    
    static func onboard() {
        
        acceptTermsAndConditions()

        let getStarted = app.buttons["getStarted"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 5))
        getStarted.tap()
        
        if let password = TestSettings.shared.password {
            let passwordLink = app.staticTexts["usePasswordLink"]
            XCTAssertTrue(passwordLink.waitForExistence(timeout: 5))
            
            passwordLink.tap()
            
            // Can test invalid password length
            let passwordField = app.secureTextFields["passwordField"]
            XCTAssertTrue(passwordField.waitForExistence(timeout: 5))
            
            passwordField.tap()
            passwordField.typeText(password)
            
            let passwordConfirmField = app.secureTextFields["passwordConfirmField"]
            XCTAssertTrue(passwordConfirmField.waitForExistence(timeout: 5))
            
            passwordConfirmField.tap()
            passwordConfirmField.typeText(password)
            passwordConfirmField.typeText("\n")
            
            let createPasswordButton = app.buttons["createPasswordButton"]
            XCTAssertTrue(createPasswordButton.waitForExistence(timeout: 5))
            createPasswordButton.tap()
        } else {
            let beginFaceSanButton = app.buttons["beginFaceSanButton"]
            XCTAssertTrue(beginFaceSanButton.waitForExistence(timeout: 5))
            beginFaceSanButton.tap()
        }

        addPhrase(inputButton: "generatePhraseButton", label: "Generated Phrase", expectPaywall: false, onboarding: true)
        let noThanksButton = app.buttons["noThanksButton"]
        XCTAssertTrue(noThanksButton.waitForExistence(timeout: 5))
        noThanksButton.tap()
        
        let homeTab = app.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5))
        XCTAssertTrue(homeTab.isSelected)
        
        XCTAssertTrue(app.buttons["My Phrases"].exists)
        XCTAssertTrue(app.buttons["Settings"].exists)
    }
    
    static func addPhrase(inputButton: String, label: String, expectPaywall: Bool, onboarding: Bool) {
        
        if !onboarding {
            let homeTab = app.buttons["Home"]
            XCTAssertTrue(homeTab.waitForExistence(timeout: 30))
            homeTab.tap()
            
            let addSeedPhraseButton = app.buttons["addSeedPhraseButton"]
            XCTAssertTrue(addSeedPhraseButton.waitForExistence(timeout: 5))
            addSeedPhraseButton.tap()
        }
        
        TestHelper.selectAddPhraseOption(inputType: inputButton)
        
        switch inputButton {
        case "enterPhraseButton":
            let enterFirstWordButton = app.buttons["enterWordButton"]
            XCTAssertTrue(enterFirstWordButton.waitForExistence(timeout: 5))
            enterFirstWordButton.tap()
            
            let words = TestSettings.shared.words
            words.enumerated().forEach { (index, word) in
                let wordEntryTextField = app.textFields["wordEntryTextField"]
                XCTAssertTrue(wordEntryTextField.waitForExistence(timeout: 5))
                
                wordEntryTextField.tap()
                wordEntryTextField.typeText(word)
                
                let wordButton = app.buttons[word]
                XCTAssertTrue(wordButton.waitForExistence(timeout: 5))
                wordButton.tap()
                
                let enterNextWordButton = app.buttons["enterWordButton"]
                XCTAssertTrue(enterNextWordButton.waitForExistence(timeout: 5))
                XCTAssertTrue(app.staticTexts["\(index+1) word\(index > 0 ? "s" : "") total"].exists)
                XCTAssertTrue(app.staticTexts[word].exists)
                if word == words.last {
                    app.buttons["finishButton"].tap()
                } else {
                    enterNextWordButton.tap()
                }
            }
            reviewAndSaveSeedPhrase(label: label, expectPaywall: expectPaywall, numWords: words.count, expectedWords: words)
            
        case "pastePhraseButton":
            let words = TestSettings.shared.words
            let pasteFromClipboardButton = app.buttons["pasteFromClipboardButton"]
            XCTAssertTrue(pasteFromClipboardButton.waitForExistence(timeout: 5))
            pasteFromClipboardButton.tap()
            
            if TestSettings.shared.springboardApp.alerts.buttons["Allow Paste"].exists {
                TestSettings.shared.springboardApp.alerts.buttons["Allow Paste"].tap()
            }

            reviewAndSaveSeedPhrase(label: label, expectPaywall: expectPaywall, numWords: words.count, expectedWords: words)
            
        case "generatePhraseButton":
            let generateButton = app.buttons["generateButton"]
            XCTAssertTrue(generateButton.waitForExistence(timeout: 5))
            generateButton.tap()
            reviewAndSaveSeedPhrase(label: label, expectPaywall: false, numWords: 24, expectedWords: nil)
            
        case "photoPhraseButton":
            
            let startPhoto = app.buttons["startPhoto"]
            XCTAssertTrue(startPhoto.waitForExistence(timeout: 5))
            startPhoto.tap()
            
            if TestSettings.shared.springboardApp.alerts.buttons["Allow"].exists {
                TestSettings.shared.springboardApp.alerts.buttons["Allow"].tap()
            }
            let takeAPhoto = app.buttons["takeAPhoto"]
            XCTAssertTrue(takeAPhoto.waitForExistence(timeout: 5))
            takeAPhoto.tap()
            
            if TestSettings.shared.springboardApp.alerts.buttons["Allow"].exists {
                TestSettings.shared.springboardApp.alerts.buttons["Allow"].tap()
                takeAPhoto.tap()
            }
            
            let usePhoto = app.buttons["usePhoto"]
            XCTAssertTrue(usePhoto.waitForExistence(timeout: 5))
            usePhoto.tap()
            
            
            reviewAndSaveSeedPhrase(label: label, expectPaywall: false, numWords: 0, expectedWords: nil)
            
        default:
            XCTFail("invalid button type")
        }
    }
    
    static func acceptTermsAndConditions() {
        let reviewButton = app.buttons["reviewTermsButton"]
        XCTAssertTrue(reviewButton.waitForExistence(timeout: 50))

        reviewButton.tap()

        let terms = app.webViews["termsWebView"]
        XCTAssertTrue(terms.waitForExistence(timeout: 5))

        let acceptButton = app.buttons["acceptTermsButton"]
        XCTAssertTrue(acceptButton.waitForExistence(timeout: 5))

        acceptButton.tap()
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
            
            let nextButton = app.buttons["nextButton"]
            XCTAssertTrue(nextButton.waitForExistence(timeout: 5))
            nextButton.tap()
        }
        
        let labelTextField = app.textFields["labelTextField"]
        XCTAssertTrue(labelTextField.waitForExistence(timeout: 5))

        labelTextField.tap()
        labelTextField.typeText(label)

        let saveButton = app.buttons["saveButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.tap()
        
        if expectPaywall {
            let purchaseYearlyButton = app.buttons["purchaseYearlyButton"]
            XCTAssertTrue(purchaseYearlyButton.waitForExistence(timeout: 5))
            XCTAssertTrue(app.buttons["purchaseMonthlyButton"].waitForExistence(timeout: 5))
            purchaseYearlyButton.tap()
        }

        let okButton = app.buttons["okButton"]
        XCTAssertTrue(okButton.waitForExistence(timeout: 5))

        okButton.tap()

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
            let haveMyOwnButton = app.buttons["haveMyOwnButton"]
            XCTAssertTrue(haveMyOwnButton.waitForExistence(timeout: 5))
            haveMyOwnButton.tap()
        }
        
        let addPhraseButton = app.buttons[inputType]
        XCTAssertTrue(addPhraseButton.waitForExistence(timeout: 5))
        addPhraseButton.tap()
    }
}
