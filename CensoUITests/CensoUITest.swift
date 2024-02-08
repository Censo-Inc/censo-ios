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
        TestHelper.onboard()
    }
    
    func test01_PastePhrase() throws {
        TestHelper.addPhrase(inputButton: "pastePhraseButton", label: "Pasted Phrase", expectPaywall: true, onboarding: false)
    }
    
    func test02_EnterPhrase() throws {
        TestHelper.addPhrase(inputButton: "enterPhraseButton", label: "Entered Word Phrase", expectPaywall: false, onboarding: false)
    }
    
    func test03_PhotoPhrase() throws {
        try XCTSkipIf(TestSettings.shared.isSimulator, "Tests requiring camera access cannot run on simulator")
        
        TestHelper.addPhrase(inputButton: "photoPhraseButton", label: "Photo Phrase", expectPaywall: false, onboarding: false)
    }

    func test04_PromoCode() throws {
        TestHelper.acceptTermsAndConditions()
        
        let app = TestSettings.shared.app!
        
        let getPromoCode = app.buttons["getPromoCode"]
        XCTAssertTrue(getPromoCode.waitForExistence(timeout: 5))
        getPromoCode.tap()
        
        let promoCodeEntry = app.textFields["promoCodeEntry"]
        XCTAssertTrue(promoCodeEntry.waitForExistence(timeout: 5))
        promoCodeEntry.tap()
        promoCodeEntry.typeText("TESTCODE")

        let submitPromoCodeButton = app.buttons["submitPromoCode"]
        XCTAssertTrue(submitPromoCodeButton.waitForExistence(timeout: 5))
        submitPromoCodeButton.tap()

        let getStarted = TestSettings.shared.app!.buttons["getStarted"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 5))
        getStarted.tap()
        
        let beginFaceSanButton = app.buttons["beginFaceSanButton"]
        XCTAssertTrue(beginFaceSanButton.waitForExistence(timeout: 5))
    }
}
