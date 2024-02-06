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
        TestHelper.dumpApp()
    }

    func test00_Onboarding() throws {
        TestSettings.shared.password = "MyPassword123!MyPassword123!MyPassword123!"
        TestHelper.onboard(phraseInputButton: "generatePhraseButton")
        TestHelper.validateHomeScreen(numPhrases: 1, numApprovers: 0)
        TestHelper.validateMyPhrasesScreen(expectedPhraseLabels: [TestSettings.shared.firstPhraseLabel])
    }
    
    func test01_PastePhrase() throws {
        TestHelper.addPhrase(inputButton: "pastePhraseButton", label: "PastedPhrase", expectPaywall: false, onboarding: false)
        TestHelper.validateHomeScreen(numPhrases: 2, numApprovers: 0)
        TestHelper.validateMyPhrasesScreen(expectedPhraseLabels: [TestSettings.shared.firstPhraseLabel, "PastedPhrase"])
    }
    
    func test02_RenamePhrase() throws {
        let app = TestSettings.shared.app!
        let phraseLabel = TestSettings.shared.firstPhraseLabel
        let renamedPhraseLabel = "Renamed\(phraseLabel)"
        
        app.waitForButtonAndTap(buttonIdentifier: "My Phrases")
        app.waitForButtonAndTap(buttonIdentifier: "seedPhraseEdit0Button")
        app.waitForStaticText(text: phraseLabel)
        
        app.waitForButtonAndTap(buttonIdentifier: "Rename")
        app.enterText(fieldIdentifier: "renameTextField", inputText: renamedPhraseLabel, expectedDefaultValue: phraseLabel)
        app.waitForButtonAndTap(buttonIdentifier: "saveButton")
        
        app.waitForStaticText(text: renamedPhraseLabel)
        XCTAssertFalse(app.staticTexts[phraseLabel].exists)
        
        TestSettings.shared.firstPhraseLabel = renamedPhraseLabel
        
        TestHelper.validateHomeScreen(numPhrases: 2, numApprovers: 0)
        TestHelper.validateMyPhrasesScreen(expectedPhraseLabels: [TestSettings.shared.firstPhraseLabel, "PastedPhrase"])
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
        textField.enterText(text: "Delete \(phraseLabel)")
        alert.waitForButtonAndTap(buttonIdentifier: "confirmDeleteConfirmationButton")
        
        app.waitForStaticText(text: "PastedPhrase")
        XCTAssertFalse(app.staticTexts[phraseLabel].exists)
        
        TestHelper.validateHomeScreen(numPhrases: 1, numApprovers: 0)
        TestHelper.validateMyPhrasesScreen(expectedPhraseLabels: ["PastedPhrase"])
    }
    
    func test04_EnterPhrase() throws {
        TestHelper.addPhrase(inputButton: "enterPhraseButton", label: "EnteredWordPhrase", expectPaywall: false, onboarding: false)
        TestHelper.validateHomeScreen(numPhrases: 2, numApprovers: 0)
        TestHelper.validateMyPhrasesScreen(expectedPhraseLabels: ["PastedPhrase", "EnteredWordPhrase"])
    }
    
    func test05_PhotoPhrase() throws {
        try XCTSkipIf(TestSettings.shared.isSimulator, "Tests requiring camera access cannot run on simulator")
        
        TestHelper.addPhrase(inputButton: "photoPhraseButton", label: "PhotoPhrase", expectPaywall: false, onboarding: false)
        TestHelper.validateHomeScreen(numPhrases: 3, numApprovers: 0)
        TestHelper.validateMyPhrasesScreen(expectedPhraseLabels: ["PastedPhrase", "EnteredWordPhrase", "PhotoPhrase"])
    }
    
    func test06_Access() throws {
        let app = TestSettings.shared.app!
        app.waitForButtonAndTap(buttonIdentifier: "My Phrases")
        app.waitForButtonAndTap(buttonIdentifier: "Begin access Button")
        app.waitForStaticText(text: "Select the seed phrase you would like to access:")
        
        XCTAssertTrue(app.buttons["PastedPhrase"].exists)
        XCTAssertTrue(app.buttons["EnteredWordPhrase"].exists)
        if TestSettings.shared.isSimulator {
            XCTAssertEqual(2, TestHelper.imagesByLabel(label: "Forward"))
        } else {
            XCTAssertTrue(app.buttons["PhotoPhrase"].exists)
            XCTAssertEqual(3, TestHelper.imagesByLabel(label: "Forward"))
        }
        
        TestHelper.accessSeedPhrase(
            label: "PastedPhrase",
            numWords: TestSettings.shared.words().count,
            expectedWords: TestSettings.shared.words()
        )
        XCTAssertEqual(1, TestHelper.imagesByLabel(label: "Selected"))
        
        
        TestHelper.accessSeedPhrase(
            label: "EnteredWordPhrase",
            numWords: TestSettings.shared.words().count,
            expectedWords: TestSettings.shared.words()
        )
        XCTAssertEqual(2, TestHelper.imagesByLabel(label: "Selected"))
        
        if !TestSettings.shared.isSimulator {
            TestHelper.accessSeedPhrase(
                label: "PhotoPhrase",
                numWords: 0
            )
            XCTAssertEqual(3, TestHelper.imagesByLabel(label: "Selected"))
        }
        
        app.waitForButtonAndTap(buttonIdentifier: "finishedButton")
        
        // no alert since no approvers or timelock
        XCTAssertEqual(app.alerts.count, 0)
        
        app.waitForButtonAndTap(buttonIdentifier: "My Phrases")
    }
    
    func test07_TimelockSettings() throws {
        let app = TestSettings.shared.app!
        app.waitForButtonAndTap(buttonIdentifier: "Settings")
        XCTAssertTrue(app.staticTexts["Lock App"].exists)
        XCTAssertTrue(app.staticTexts["Enable Timelock"].exists)
        XCTAssertTrue(app.staticTexts["Delete My Data"].exists)
        
        app.waitForButtonAndTap(buttonIdentifier: "enableTimelockButton")
        
        app.waitForStaticText(text: "Disable Timelock")
        app.waitForButtonAndTap(buttonIdentifier: "disableTimelockButton")
        
        // try to cancel it but then cancel the cancel
        app.waitForStaticText(text: "Cancel Disable Timelock")
        app.waitForButtonAndTap(buttonIdentifier: "cancelDisableTimelockButton")
        var alert = app.waitForAlert(alertIdentifier: "Cancel Disable Timelock")
        alert.waitForButtonAndTap(buttonIdentifier: "CancelCancelDisableTimelockButton")
        app.waitForStaticText(text: "Cancel Disable Timelock")
        
        // this waits for timelock to expire - it is 30 seconds + repeater app task runs every 30
        // re-enable, disable, then cancel the disable and confirm
        app.waitForButtonAndTap(buttonIdentifier: "enableTimelockButton", timeout: 70)
        
        app.waitForStaticText(text: "Disable Timelock")
        app.waitForButtonAndTap(buttonIdentifier: "disableTimelockButton")
        
        // confirm the cancellation this time
        app.waitForStaticText(text: "Cancel Disable Timelock")
        app.waitForButtonAndTap(buttonIdentifier: "cancelDisableTimelockButton")
        alert = app.waitForAlert(alertIdentifier: "Cancel Disable Timelock")
        alert.waitForButtonAndTap(buttonIdentifier: "ConfirmCancelDisableTimelockButton")
        
        app.waitForStaticText(text: "Disable Timelock")
    }
    
    func test08_AccessWithTimelock() throws {
        let app = TestSettings.shared.app!
        app.waitForButtonAndTap(buttonIdentifier: "My Phrases")
        
        // start the access
        app.waitForButtonAndTap(buttonIdentifier: "Begin access Button")
        app.waitForStaticText(text: "Timelock expires in: less than 1 minute")
    
        // cancel the access
        app.waitForButtonAndTap(buttonIdentifier: "cancelAccessButton")
        var alert = app.waitForAlert(alertIdentifier: "Cancel access")
        alert.waitForStaticText(text: "If you cancel access you will need to wait for the timelock period to access your phrases again. Are you sure?")
        alert.waitForButtonAndTap(buttonIdentifier: "confirmCancelAccessButton")
        
        // when begin access appears start over
        app.waitForButtonAndTap(buttonIdentifier: "Begin access Button")
        app.waitForStaticText(text: "Timelock expires in: less than 1 minute")
        
        // this waits for timelock to expire - it is 30 seconds + repeater app task runs every 30
        app.waitForButtonAndTap(buttonIdentifier: "Show seed phrases Button", timeout: 70)
        
        TestHelper.accessSeedPhrase(
            label: "PastedPhrase",
            numWords: TestSettings.shared.words().count,
            expectedWords: TestSettings.shared.words()
        )
        XCTAssertEqual(1, TestHelper.imagesByLabel(label: "Selected"))
        
        app.waitForButtonAndTap(buttonIdentifier: "finishedButton")
        // handle the exit alert but cancel
        alert = app.waitForAlert(alertIdentifier: "Exit accessing phrases")
        alert.waitForStaticText(text: "Are you all finished accessing phrases? If you exit you will need to wait for the timelock period to access your phrases again.")
        alert.waitForButtonAndTap(buttonIdentifier: "cancelExitAccessingPhrasesButton")
        
        // confirm the exit alert this time
        app.waitForButtonAndTap(buttonIdentifier: "finishedButton")
        alert = app.waitForAlert(alertIdentifier: "Exit accessing phrases")
        alert.waitForButtonAndTap(buttonIdentifier: "confirmExitAccessingPhrasesButton")
        
        let _ = app.waitForButton(buttonIdentifier: "Begin access Button")
    }
    
    func test09_LockAndUnlockWithPassword() throws {
        TestHelper.lockAndUnlock()
    }
    
    func test10_DeleteAllDataSettings() throws {
        let app = TestSettings.shared.app!
        app.waitForButtonAndTap(buttonIdentifier: "Settings")
        XCTAssertTrue(app.staticTexts["Delete My Data"].exists)
        
        app.waitForButtonAndTap(buttonIdentifier: "deleteMyDataButton")
        
        let numSeedPhrases = TestSettings.shared.isSimulator ? 2 : 3
        let confirmationText = "Delete my \(numSeedPhrases) seed phrase\(numSeedPhrases == 1 ? "" : "s")"
        var alert = app.waitForAlert(alertIdentifier: "Delete Data Confirmation")
        XCTAssertTrue(alert.staticTexts["Delete Data Confirmation"].exists)
        let predicate = NSPredicate(format: "label CONTAINS[c] '\"\(confirmationText)\"'")
        XCTAssertEqual(alert.staticTexts.containing(predicate).count, 1)
        let predicate2 = NSPredicate(format: "label CONTAINS[c] 'This action will delete ALL of your data. Seed phrases you have added will no longer be accessible. This action cannot be reversed.'")
        XCTAssertEqual(alert.staticTexts.containing(predicate).count, 1)
        alert.waitForButtonAndTap(buttonIdentifier: "cancelDeleteAllDataButton")
        
        app.waitForButtonAndTap(buttonIdentifier: "deleteMyDataButton")
        alert = app.waitForAlert(alertIdentifier: "Delete Data Confirmation")
        alert.textFields.firstMatch.enterText(text: "Deletesomething")
        alert.waitForButtonAndTap(buttonIdentifier: "confirmDeleteAllDataButton")
        
        alert = app.waitForAlert(alertIdentifier: "Confirmation does not match")
        alert.waitForButtonAndTap(buttonIdentifier: "retryConfirmationDoesNotMatchButton")
        
        alert = app.waitForAlert(alertIdentifier: "Delete Data Confirmation")
        alert.textFields.firstMatch.enterText(text: confirmationText)
        alert.waitForButtonAndTap(buttonIdentifier: "confirmDeleteAllDataButton")
        
        let _ = app.waitForButton(buttonIdentifier: "Sign in with Apple")
        
        // onboard with a french phrase and use facetec
        TestSettings.shared.restartApp(language: PhraseLanguage.french)
        TestSettings.shared.password = nil
        TestSettings.shared.firstPhraseLabel = "FrenchPhrase"
        TestHelper.onboard(phraseInputButton: "pastePhraseButton")
    }
    
    func test11_ChangeLanguages() throws {
        let app = TestSettings.shared.app!
        
        // add a phrase in japanese
        TestHelper.addPhrase(
            inputButton: "enterPhraseButton",
            label: "JapanesePhrase",
            expectPaywall: false,
            onboarding: false,
            language: PhraseLanguage.japanese
        )
        
        // access them
        app.waitForButtonAndTap(buttonIdentifier: "My Phrases")
        app.waitForButtonAndTap(buttonIdentifier: "Begin access Button")
        
        // access the japanese phrase in french
        TestHelper.accessSeedPhrase(
            label: "JapanesePhrase",
            numWords: TestSettings.shared.words().count,
            expectedWords: TestSettings.shared.words(language: .french),
            language: .french
        )
        
        // access the french phrase in english
        TestHelper.accessSeedPhrase(
            label: "FrenchPhrase",
            numWords: TestSettings.shared.words().count,
            expectedWords: TestSettings.shared.words(language: .english),
            language: .english
        )
        
        app.waitForButtonAndTap(buttonIdentifier: "finishedButton")
        
    }
    
    func test12_LockAndUnlockWithFace() throws {
        TestHelper.lockAndUnlock()
    }
}
