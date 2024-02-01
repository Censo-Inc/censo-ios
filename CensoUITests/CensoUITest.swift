//
//  SampleTest.swift
//  Censo
//
//  Created by Ata Namvari on 2023-08-09.
//

import XCTest
@testable import Censo

final class CensoUITest: XCTestCase {
    
    override func setUp() {
        continueAfterFailure = false
    }

    override func tearDown() {
        
    }

    func test00_Onboarding() throws {
        TestSettings.shared.password = "MyPassword123!MyPassword123!MyPassword123!"
        TestHelper.onboard(phraseInputButton: "generatePhraseButton")
        TestHelper.validateHomeScreen(numPhrases: 1, numApprovers: 0)
        TestHelper.validateMyPhrasesScreen(expectedPhraseLabels: [TestSettings.shared.firstPhraseLabel])
    }
    
    func test01_PastePhrase() throws {
        TestHelper.addPhrase(inputButton: "pastePhraseButton", label: "Pasted Phrase", expectPaywall: true, onboarding: false)
        TestHelper.validateHomeScreen(numPhrases: 2, numApprovers: 0)
        TestHelper.validateMyPhrasesScreen(expectedPhraseLabels: [TestSettings.shared.firstPhraseLabel, "Pasted Phrase"])
    }
    
    func test02_RenamePhrase() throws {
        let app = TestSettings.shared.app!
        let phraseLabel = TestSettings.shared.firstPhraseLabel
        let renamedPhraseLabel = "Renamed \(phraseLabel)"
        
        app.waitForButtonAndTap(buttonIdentifier: "My Phrases")
        app.waitForButtonAndTap(buttonIdentifier: "seedPhraseEdit0Button")
        app.waitForStaticText(text: phraseLabel)
        
        app.waitForButtonAndTap(buttonIdentifier: "Rename")
        app.enterText(fieldIdentifier: "renameTextField", inputText: renamedPhraseLabel, expectedDefaultValue: phraseLabel)
        app.waitForButtonAndTap(buttonIdentifier: "saveButton")
        
        app.waitForStaticText(text: renamedPhraseLabel)
        XCTAssertFalse(app.staticTexts["Generated"].exists)
        
        TestSettings.shared.firstPhraseLabel = renamedPhraseLabel
        
        TestHelper.validateHomeScreen(numPhrases: 2, numApprovers: 0)
        TestHelper.validateMyPhrasesScreen(expectedPhraseLabels: [TestSettings.shared.firstPhraseLabel, "Pasted Phrase"])
    }
    
    func test03_DeletePhrase() throws {
        let app = TestSettings.shared.app!
        let phraseLabel = TestSettings.shared.firstPhraseLabel
        
        app.waitForButtonAndTap(buttonIdentifier: "My Phrases")
        app.waitForButtonAndTap(buttonIdentifier: "seedPhraseEdit0Button")
        app.waitForStaticText(text: phraseLabel)
        
        app.waitForButtonAndTap(buttonIdentifier: "Delete")
        
        let alert = app.waitForAlert(alertIdentifier: "Delete Confirmation")
        alert.waitForStaticText(text: "Delete Confirmation")

        XCTAssertTrue(alert.staticTexts["Delete Confirmation"].exists)
        XCTAssertTrue(alert.staticTexts["You are about to delete this phrase. If you are sure, type:\n\"Delete \(phraseLabel)\""].exists)
        let textField = alert.textFields.firstMatch
        textField.clearAndEnterText(text: "Delete \(phraseLabel)")
        alert.waitForButtonAndTap(buttonIdentifier: "confirmDeleteConfirmationButton")
        
        app.waitForStaticText(text: "Seed Phrases")
        XCTAssertFalse(app.staticTexts[phraseLabel].exists)
        
        TestHelper.validateHomeScreen(numPhrases: 1, numApprovers: 0)
        TestHelper.validateMyPhrasesScreen(expectedPhraseLabels: ["Pasted Phrase"])
    }
    
    
    func test04_EnterPhrase() throws {
        TestHelper.addPhrase(inputButton: "enterPhraseButton", label: "Entered Word Phrase", expectPaywall: false, onboarding: false)
        TestHelper.validateHomeScreen(numPhrases: 2, numApprovers: 0)
        TestHelper.validateMyPhrasesScreen(expectedPhraseLabels: ["Pasted Phrase", "Entered Word Phrase"])
    }
    
    func test05_PhotoPhrase() throws {
        try XCTSkipIf(TestSettings.shared.isSimulator, "Tests requiring camera access cannot run on simulator")
        
        TestHelper.addPhrase(inputButton: "photoPhraseButton", label: "Photo Phrase", expectPaywall: false, onboarding: false)
        TestHelper.validateHomeScreen(numPhrases: 3, numApprovers: 0)
        TestHelper.validateMyPhrasesScreen(expectedPhraseLabels: ["Pasted Phrase", "Entered Word Phrase", "Photo Phrase"])
    }

}
