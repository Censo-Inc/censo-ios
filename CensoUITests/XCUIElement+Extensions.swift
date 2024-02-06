//
//  XCUI+Extensions.swift
//  CensoUITests
//
//  Created by Brendan Flood on 1/30/24.
//

import Foundation
import XCTest

extension XCUIElement {
    /**
     Removes any current text in the field before typing in the new value
     - Parameter text: the text to enter into the field
     */
    func enterText(text: String) {
        guard let _ = self.value as? String else {
            XCTFail("Tried to clear and enter text into a non string value")
            return
        }

        self.doubleTap()
        self.typeText(text)
        if self.value as? String != text {
            print("******* wrong text entered ******** ")
            self.doubleTap()
            self.typeText(text)
        }
    }
    
    
    func waitForButtonAndTap(buttonIdentifier: String, timeout: TimeInterval = 5) {
        waitForButton(buttonIdentifier: buttonIdentifier, timeout: timeout).tap()
    }
    
    func waitForButton(buttonIdentifier: String, timeout: TimeInterval = 5) -> XCUIElement {
        let app = TestSettings.shared.app!
        let button = app.buttons[buttonIdentifier]
        XCTAssertTrue(button.waitForExistence(timeout: timeout))
        return button
    }
    
    func waitForStaticText(text: String) {
        let app = TestSettings.shared.app!
        let staticText = app.staticTexts[text]
        XCTAssertTrue(staticText.waitForExistence(timeout: 5))
    }
    
    func enterText(fieldIdentifier: String, inputText: String, expectedDefaultValue: String? = nil) {
        let app = TestSettings.shared.app!
        let textField = app.textFields[fieldIdentifier]
        XCTAssertTrue(textField.waitForExistence(timeout: 5))
        if let expectedDefaultValue {
            XCTAssertEqual(textField.value as? String, expectedDefaultValue)
        }
        textField.enterText(text: inputText)
    }
    
    func waitForAlert(alertIdentifier: String) -> XCUIElement {
        let app = TestSettings.shared.app!
        let alert = app.alerts[alertIdentifier]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        return alert
    }
    
    func enterSecureText(fieldIdentifier: String, secureText: String, enterReturn: Bool) {
        let app = TestSettings.shared.app!
        let secureTextField = app.secureTextFields[fieldIdentifier]
        XCTAssertTrue(secureTextField.waitForExistence(timeout: 5))
        
        secureTextField.doubleTap()
        secureTextField.typeText(secureText)
        if enterReturn {
            secureTextField.typeText("\n")
        }
    }
}
