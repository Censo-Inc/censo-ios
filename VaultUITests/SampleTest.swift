//
//  SampleTest.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-09.
//

import XCTest
import Vault

final class SampleTest: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["testing"]
        app.launch()
    }

    override func tearDownWithError() throws {
        //Keychain.removeVault()
    }

    func testPhraseEntryForwards() throws {
        app.buttons["addPhrase"].tap()

        let phraseName = "Test"

        let name = app.textFields["nameField"]
        name.tap()
        name.typeText(phraseName)

        let myTestPhrase = "obvious logic scout door humble speak stamp bean tape mutual rough pride airport yellow artwork ranch prevent pact identify globe garlic leisure vital analyst"

        let words = app.textFields["wordsField"]
        words.tap()
        words.typeText(myTestPhrase)

        let addButton = app.buttons["addToVaultButton"]
        addButton.tap()

        let newPhrase = app.buttons[phraseName]
        XCTAssertTrue(newPhrase.waitForExistence(timeout: 5))

        newPhrase.tap()

        let myTestWords = myTestPhrase.split(separator: " ").map(String.init)

        for i in 0..<myTestWords.count {
            let number = app.staticTexts["\(i+1)"]
            XCTAssertTrue(number.waitForExistence(timeout: 5))

            let message = app.staticTexts[myTestWords[i]]
            XCTAssertTrue(message.waitForExistence(timeout: 5))

            if i % 3 == 2 {
                let nextButton = app.buttons["nextWordSetButton"]
                nextButton.tap()
            }
        }
    }

    func testPhraseEntryBackwards() throws {
        app.buttons["addPhrase"].tap()

        let phraseName = "Test"

        let name = app.textFields["nameField"]
        name.tap()
        name.typeText(phraseName)

        let myTestPhrase = "obvious logic scout door humble speak stamp bean tape mutual rough pride airport yellow artwork ranch prevent pact identify globe garlic leisure vital analyst"

        let words = app.textFields["wordsField"]
        words.tap()
        words.typeText(myTestPhrase)

        let addButton = app.buttons["addToVaultButton"]
        addButton.tap()

        let newPhrase = app.buttons[phraseName]
        XCTAssertTrue(newPhrase.waitForExistence(timeout: 5))

        newPhrase.tap()

        let myTestWords = myTestPhrase.split(separator: " ").map(String.init)

        for i in 0..<myTestWords.count {
            if i % 3 == 0 {
                let previousButton = app.buttons["previousWordSetButton"]
                previousButton.tap()
            }

            let j = myTestWords.count - i - 1

            let number = app.staticTexts["\(j+1)"]
            XCTAssertTrue(number.waitForExistence(timeout: 5))

            let message = app.staticTexts[myTestWords[j]]
            XCTAssertTrue(message.waitForExistence(timeout: 5))
        }
    }
}
