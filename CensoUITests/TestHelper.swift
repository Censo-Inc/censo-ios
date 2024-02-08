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
    
    static func addPhrase(inputButton: String, label: String, expectPaywall: Bool, onboarding: Bool, language: PhraseLanguage? = nil) {
        
        if !onboarding {
            app.waitForButtonAndTap(buttonIdentifier: "Home")
            app.waitForButtonAndTap(buttonIdentifier: "addSeedPhraseButton")
        }
        
        if let language {
            selectLanguage(language: language)
        }
        TestHelper.selectAddPhraseOption(inputType: inputButton)
        
        switch inputButton {
        case "enterPhraseButton":
            app.waitForButtonAndTap(buttonIdentifier: "enterWordButton")
            
            let words = TestSettings.shared.words()
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
            let words = TestSettings.shared.words()
            
            app.waitForButtonAndTap(buttonIdentifier: "pasteFromClipboardButton")
            respondToPasteAlertIfPresent()
            
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
    
    static func selectLanguage(language: PhraseLanguage) {
        app.waitForStaticText(text: "languagePickerText")
        let staticText = app.staticTexts["languagePickerText"]
        staticText.tap()
        app.waitForButtonAndTap(buttonIdentifier: TestSettings.shared.languageButtonIdentifier[language]!)
        TestSettings.shared.currentLanguage = language
    }
    
    static func acceptTermsAndConditions() {
        app.waitForButtonAndTap(buttonIdentifier: "reviewTermsButton", timeout: 30)

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
            XCTAssertTrue(app.staticTexts[label].exists, label)
        }
    }
    
    static func reviewAndSaveSeedPhrase(label: String, expectPaywall: Bool, numWords: Int, expectedWords: [String]?) {
        if numWords > 0 {
            reviewWords(numWords: numWords, expectedWords: expectedWords, doneButtonIdentifier: "nextButton")
        }
        
        app.enterText(fieldIdentifier: "labelTextField", inputText: label)
        app.waitForButtonAndTap(buttonIdentifier: "saveButton")
        
        if expectPaywall {
            XCTAssertTrue(app.buttons["purchaseMonthlyButton"].waitForExistence(timeout: 5))
            app.waitForButtonAndTap(buttonIdentifier: "purchaseYearlyButton")
        }

        app.waitForButtonAndTap(buttonIdentifier: "okButton")
    }
    
    static func accessSeedPhrase(label: String, numWords: Int, expectedWords: [String]? = nil, language: PhraseLanguage? = nil) {
        
        app.waitForButtonAndTap(buttonIdentifier: label)
        if let language {
            selectLanguage(language: language)
        }
        app.waitForButtonAndTap(buttonIdentifier: "getStarted")
        
        if let password = TestSettings.shared.password {
            enterPassword(password: password)
        }
        
        XCTAssertTrue(app.buttons["doneViewingPhraseButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Access ends in: 15 min"].exists)
        
        if numWords != 0 {
            XCTAssertTrue(app.staticTexts["swipe back and forth to review words"].exists)
            
            reviewWords(
                numWords: numWords,
                expectedWords: expectedWords,
                doneButtonIdentifier: "doneViewingPhraseButton"
            )
        } else {
            XCTAssertTrue(app.staticTexts["Zoom in to see the words"].exists)
            app.waitForButtonAndTap(buttonIdentifier: "doneViewingPhraseButton")
        }
    }
    
    static func enterPassword(password: String, shouldPass: Bool = true) {
        app.waitForStaticText(text: "Enter your password")
        app.enterSecureText(fieldIdentifier: "passwordInputTextField", secureText: password, enterReturn: false)
        app.waitForButtonAndTap(buttonIdentifier: "continueButton")
        if shouldPass {
            if app.staticTexts["Password was invalid"].waitForExistence(timeout: 1) {
                print(" ******* wrong password entered")
                app.enterSecureText(fieldIdentifier: "passwordInputTextField", secureText: password, enterReturn: false)
                app.waitForButtonAndTap(buttonIdentifier: "continueButton")
            }
        }
        
    }
    
    static func imagesByLabel(label: String) -> Int {
        var count = 0
        for i in 0..<app.images.count {
            let element = app.images.element(boundBy: i)
            if element.label == label {
                count = count + 1
            }
        }
        return count
    }
    
    static func reviewWords(numWords: Int, expectedWords: [String]?, doneButtonIdentifier: String) {
        for index in 1...numWords {
            let word = app.staticTexts[getWordText(index: index)]
            XCTAssertTrue(word.waitForExistence(timeout: 5))
            if let expectedWords {
                XCTAssertTrue(app.staticTexts[expectedWords[index - 1]].exists)
            }
            if index != numWords {
                word.swipeLeft()
            }
        }
        
        app.waitForButtonAndTap(buttonIdentifier: doneButtonIdentifier)
    }
    
    static func lockAndUnlock() {
        app.waitForButtonAndTap(buttonIdentifier: "Settings")
        XCTAssertTrue(app.staticTexts["Lock app"].exists)
        
        app.waitForButtonAndTap(buttonIdentifier: "lockButton")
        
        let unlockButton = app.waitForButton(buttonIdentifier: "lockContinueButton")
        XCTAssertFalse(app.staticTexts["Having trouble with password verification?"].exists)
        unlockButton.tap()
        if let password = TestSettings.shared.password {
            enterPassword(password: "badpassword", shouldPass: false)
            app.waitForStaticText(text: "Password was invalid")
            enterPassword(password: password)
        }

        let _ = app.waitForButton(buttonIdentifier: "Home")
    }
    
    static func respondToPasteAlertIfPresent() {
        if TestSettings.shared.springboardApp.alerts.buttons["Allow Paste"].exists {
            TestSettings.shared.springboardApp.alerts.buttons["Allow Paste"].tap()
        }
    }
    
    static func monitorAndHandlePasteAlerts() {
        // XCUIApplication framework does not handle paste alerts and the tap() of the button hangs for 60 seconds.
        // this spins up a thread which checks for the alert after a few seconds. This should be called before the
        // the button is tapped
        class PasteAlertMonitorThread: Thread {
            override func main() {
                Thread.sleep(forTimeInterval: 5)
                DispatchQueue.main.async {
                    if TestSettings.shared.springboardApp.alerts.buttons["Allow Paste"].exists {
                        TestSettings.shared.springboardApp.alerts.buttons["Allow Paste"].tap()
                    }
                }
            }
        }

        PasteAlertMonitorThread().start()
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
    
    static func dumpApp() {
        print("buttons: \(app.buttons.debugDescription)")
        print("textFields: \(app.textFields.debugDescription)")
        print("staticTexts: \(app.staticTexts.debugDescription)")
        print("secureText: \(app.secureTextFields.debugDescription)")
        print("navigationBars: \(app.navigationBars.debugDescription)")
        print("images: \(app.images.debugDescription)")
        print("alerts: \(app.alerts.debugDescription)")
        print("scrollbars: \(app.scrollBars.debugDescription)")
        print("scrollviews: \(app.scrollViews.debugDescription)")
        print("menus: \(app.menus.debugDescription)")
        print("User Identifier = \(TestSettings.shared.userIdentifier)")
    }
}
