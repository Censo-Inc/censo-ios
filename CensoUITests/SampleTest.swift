//
//  SampleTest.swift
//  Censo
//
//  Created by Ata Namvari on 2023-08-09.
//

import XCTest
@testable import Censo

final class SampleTest: XCTestCase {
    var app: XCUIApplication!
    var userId: String!

    override func setUpWithError() throws {
        continueAfterFailure = false
        userId = "testAppleUserIdentifier-\(UUID().uuidString)"
        app = XCUIApplication()
        app.launchArguments = ["testing", userId]
        app.launch()
    }

    override func tearDownWithError() throws {

    }

    func test00_Onboarding() throws {
        let reviewButton = app.buttons["reviewTermsButton"]
        XCTAssertTrue(reviewButton.waitForExistence(timeout: 50))

        reviewButton.tap()

        let terms = app.webViews["termsWebView"]
        XCTAssertTrue(terms.waitForExistence(timeout: 5))

        let acceptButton = app.buttons["acceptTermsButton"]
        XCTAssertTrue(acceptButton.waitForExistence(timeout: 5))

        acceptButton.tap()

        let getStarted = app.buttons["getStarted"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 5))

        getStarted.tap()

        let passwordLink = app.staticTexts["usePasswordLink"]
        XCTAssertTrue(passwordLink.waitForExistence(timeout: 5))

        passwordLink.tap()

        // Can test invalid password length
        let passwordField = app.secureTextFields["passwordField"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 5))

        passwordField.tap()
        passwordField.typeText("MyPassword123!MyPassword123!MyPassword123!")

        let passwordConfirmField = app.secureTextFields["passwordConfirmField"]
        XCTAssertTrue(passwordConfirmField.waitForExistence(timeout: 5))

        passwordConfirmField.tap()
        passwordConfirmField.typeText("MyPassword123!MyPassword123!MyPassword123!")
        passwordConfirmField.typeText("\n")

        let createPasswordButton = app.buttons["createPasswordButton"]
        XCTAssertTrue(createPasswordButton.waitForExistence(timeout: 5))

        createPasswordButton.tap()

        let generatePhraseButton = app.buttons["generatePhraseButton"]
        XCTAssertTrue(generatePhraseButton.waitForExistence(timeout: 5))

        generatePhraseButton.tap()

        let generateButton = app.buttons["generateButton"]
        XCTAssertTrue(generateButton.waitForExistence(timeout: 5))

        generateButton.tap()

        let nextButton = app.buttons["nextButton"]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 5))

        nextButton.tap()

        let labelTextField = app.textFields["labelTextField"]
        XCTAssertTrue(labelTextField.waitForExistence(timeout: 5))

        labelTextField.tap()
        labelTextField.typeText("MyPhrase")

        let saveButton = app.buttons["saveButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))

        saveButton.tap()

        let okButton = app.buttons["okButton"]
        XCTAssertTrue(okButton.waitForExistence(timeout: 5))

        okButton.tap()

        let noThanksButton = app.buttons["noThanksButton"]
        XCTAssertTrue(noThanksButton.waitForExistence(timeout: 5))

        noThanksButton.tap()
        
        let homeTab = app.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5))
        XCTAssertTrue(homeTab.isSelected)
        
        XCTAssertTrue(app.buttons["My Phrases"].exists)
        XCTAssertTrue(app.buttons["Settings"].exists)
    }

}
