//
//  ValueWrapperTests.swift
//  CensoTests
//
//  Created by Brendan Flood on 9/18/23.
//

import XCTest

@testable import Censo

final class ValueWrapperTests: XCTestCase {
    struct WrappedValues: Codable, Equatable {
        var base58EncodedPublicKey: Base58EncodedPublicKey
        var base64EncodedString: Base64EncodedString
        var participantId: ParticipantId
    }
    
    func testWrappedValuesSuccess() throws {
        
        let base58EncodedPublicKey = try EncryptionKey.generateRandomKey().publicExternalRepresentation()
        let base64EncodedString = try Base64EncodedString(value: "hello world".data(using: .utf8)!.base64EncodedString())
        let participantId = ParticipantId(bigInt: generateParticipantId())
        
        let json = "{\"base58EncodedPublicKey\": \"\(base58EncodedPublicKey.value)\", \"base64EncodedString\": \"\(base64EncodedString.value)\", \"participantId\": \"\(participantId.value)\"}"
        
        let wrappedValues = try JSONDecoder().decode(WrappedValues.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(base58EncodedPublicKey, wrappedValues.base58EncodedPublicKey)
        XCTAssertEqual(base64EncodedString, wrappedValues.base64EncodedString)
        XCTAssertEqual(participantId, wrappedValues.participantId)
        
        XCTAssertEqual(
            wrappedValues,
            try JSONDecoder().decode(WrappedValues.self, from: try JSONEncoder().encode(wrappedValues))
        )
    }
    
    func testWrappedValuesFailures() throws {
        
        let base58EncodedPublicKey = try EncryptionKey.generateRandomKey().publicExternalRepresentation()
        let base64EncodedString = try Base64EncodedString(value: "hello world".data(using: .utf8)!.base64EncodedString())
        let participantId = ParticipantId(bigInt: generateParticipantId())
        
        let jsonInvalidBase58 = "{\"base58EncodedPublicKey\": \"bad==\", \"base64EncodedString\": \"\(base64EncodedString.value)\", \"participantId\": \"\(participantId.value)\"}"
        XCTAssertThrowsError(try JSONDecoder().decode(WrappedValues.self, from: jsonInvalidBase58.data(using: .utf8)!), "expected base58 error but got none") { error in
            switch (error) {
            case  Swift.DecodingError.dataCorrupted(let context):
                XCTAssertEqual(context.debugDescription, "Invalid Base58 Key")
            default:
                XCTFail("Unexpected Error")
            }
        }
        
        let jsonInvalidBase64 = "{\"base58EncodedPublicKey\": \"\(base58EncodedPublicKey.value)\", \"base64EncodedString\": \"bad\", \"participantId\": \"\(participantId.value)\"}"
        XCTAssertThrowsError(try JSONDecoder().decode(WrappedValues.self, from: jsonInvalidBase64.data(using: .utf8)!), "expected base64 error but got none") { error in
            switch (error) {
            case  Swift.DecodingError.dataCorrupted(let context):
                XCTAssertEqual(context.debugDescription, "Invalid Base64 data")
            default:
                XCTFail("Unexpected Error")
            }
        }
        
        
        let jsonInvalidParticipantId = "{\"base58EncodedPublicKey\": \"\(base58EncodedPublicKey.value)\", \"base64EncodedString\": \"\(base64EncodedString.value)\", \"participantId\": \"badd\"}"
        XCTAssertThrowsError(try JSONDecoder().decode(WrappedValues.self, from: jsonInvalidParticipantId.data(using: .utf8)!), "expected participantId error but got none") { error in
            switch (error) {
            case  Swift.DecodingError.dataCorrupted(let context):
                XCTAssertEqual(context.debugDescription, "Invalid ParticipantId")
            default:
                XCTFail("Unexpected Error")
            }
        }
        
    }
}
