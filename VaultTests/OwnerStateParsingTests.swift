//
//  OwnerStateParsingTests.swift
//  VaultTests
//
//  Created by Brendan Flood on 9/8/23.
//

import XCTest
@testable import Vault

final class OwnerStateParsingTests: XCTestCase {
    
    func testParseOwnerState() {
        
        let noOwnerState =  "{\"contacts\":[{\"identifier\":\"contact_01h9tzr810eygsmya040f5r6at\",\"contactType\":\"Email\",\"value\":\"1acf85c1-a928-4cb5-9539-df92127b1c8e@test.com\",\"verified\":true},{\"identifier\":\"contact_01h9tzr84efxwsg3pqcg0p9805\",\"contactType\":\"Phone\",\"value\":\"+1306004633\",\"verified\":true}],\"ownerState\":null,\"biometricVerificationRequired\":true}"
        
        let initial =
        "{\"contacts\":[{\"identifier\":\"contact_01h9tzr810eygsmya040f5r6at\",\"contactType\":\"Email\",\"value\":\"1acf85c1-a928-4cb5-9539-df92127b1c8e@test.com\",\"verified\":true},{\"identifier\":\"contact_01h9tzr84efxwsg3pqcg0p9805\",\"contactType\":\"Phone\",\"value\":\"+1306004633\",\"verified\":true}],\"ownerState\":{\"type\":\"PolicySetup\",\"policy\":{\"createdAt\":\"2023-09-08T18:09:32.526Z\",\"guardians\":[{\"label\":\"Guardian 1\",\"participantId\":\"D570761fFc2ad9AFeeDcA2Bee23Facf1Ed4caD89Ba48e4dAEb1eCEdAa6eEC76D\",\"status\":{\"type\":\"Initial\",\"deviceEncryptedShard\":\"Z3VhcmRpYW4gMSBzaGFyZA==\"}},{\"label\":\"Guardian 2\",\"participantId\":\"06d65Ac7D653ceC6d7f2D9ea69dc115Be3dDaebbadFcBdcc3ed4bB51C4Af5eBB\",\"status\":{\"type\":\"Initial\",\"deviceEncryptedShard\":\"Z3VhcmRpYW4gMiBzaGFyZA==\"}},{\"label\":\"Guardian 3\",\"participantId\":\"7f3EA0e0C1B3Abc61b51D8eAbcb4e7C1fD6BdA108eE7dFcAfDDdF6642cF2faE7\",\"status\":{\"type\":\"Initial\",\"deviceEncryptedShard\":\"Z3VhcmRpYW4gMyBzaGFyZA==\"}}],\"threshold\":2,\"encryptedMasterKey\":\"BBz7rf1BzCAHgWpum12atRCzxiMW8QI98pVofDYNcO0k0f5SmZCIIndeL4NVXtl+DEi8ub6KYFWjDQsBqNgLe83kdM5AsR9Og77i5PO5Zwpj0ULQpRdCgt1XT5oFpW5Vwof07IBEXS9yFtVzOUcZ/oa3\",\"intermediateKey\":\"dFeEDwhgYbAA2Jzrsk5N8ahzzQyCpEELUbECaai8L6fM\"},\"publicMasterEncryptionKey\":\"123\"},\"biometricVerificationRequired\":false}"
        
        let invited = "{\"contacts\":[{\"identifier\":\"contact_01h9v5ec4qeds80c4k13zh73xj\",\"contactType\":\"Email\",\"value\":\"9b990f03-4917-469c-9174-93f34165dae8@test.com\",\"verified\":true},{\"identifier\":\"contact_01h9v5ec8de1h9yw144q7gmk92\",\"contactType\":\"Phone\",\"value\":\"+1726890397\",\"verified\":true}],\"ownerState\":{\"type\":\"PolicySetup\",\"policy\":{\"createdAt\":\"2023-09-08T19:49:00.583680Z\",\"guardians\":[{\"label\":\"Guardian 1\",\"participantId\":\"A8f12d5c6d25A06bC5fDC3Da0f48e5b2B08Fa8B15634E4d6adDbDFb655cc8572\",\"status\":{\"type\":\"Invited\",\"deviceEncryptedShard\":\"Z3VhcmRpYW4gMSBzaGFyZA==\",\"deviceEncryptedPin\":\"BHcKE1Nn+lrQB62VkZPCj/DjbVk6fa8V73w4w6FS1DtBJeYxnJzCtYgt6wRerAfFPcqizzPiF38hUegReyF0vSbohWPDexjCtp4VPEkuA2D6hsfR/U4m\",\"invitedAt\":\"2023-09-08T19:49:00.681848Z\"}},{\"label\":\"Guardian 2\",\"participantId\":\"A5d4818C56E0DfFAc2bBbDabbeEA5571A94a87e5D9E0fC0bAB314fCe7a05Bcc7\",\"status\":{\"type\":\"Initial\",\"deviceEncryptedShard\":\"Z3VhcmRpYW4gMiBzaGFyZA==\"}},{\"label\":\"Guardian 3\",\"participantId\":\"85727a62Bf5eaCdC0EBEa8C58e716C4Adf6f5Aa65516BA7CABE6A2f685347EDF\",\"status\":{\"type\":\"Initial\",\"deviceEncryptedShard\":\"Z3VhcmRpYW4gMyBzaGFyZA==\"}}],\"threshold\":2,\"encryptedMasterKey\":\"BOacnUfXgT20xiS7pTjR+xp7l8SdJYh3RUsxYQ+QXO8GPBD3zn81R+7IE9YwfMB5sPTNa9i2yTK8+2oMPxc7y+fVyouuUSv9cwiwogMmw4CIHf/6pkB1VS4rbAuZBNPky6eSTwwQx3U/Wl4nE1lN+rbw\",\"intermediateKey\":\"2BEt8X9pZM6QMspqZ1NTXZoq1NxpYHshBJMMiSaxWWso2\"},\"publicMasterEncryptionKey\":\"tzhMpeW9dXeUv7vETy6ZU18ZkLSwbUkxbX3DaJC6Cdy1\"},\"biometricVerificationRequired\":false}"
        
        let accepted = "{\"contacts\":[{\"identifier\":\"contact_01h9v5ec4qeds80c4k13zh73xj\",\"contactType\":\"Email\",\"value\":\"9b990f03-4917-469c-9174-93f34165dae8@test.com\",\"verified\":true},{\"identifier\":\"contact_01h9v5ec8de1h9yw144q7gmk92\",\"contactType\":\"Phone\",\"value\":\"+1726890397\",\"verified\":true}],\"ownerState\":{\"type\":\"PolicySetup\",\"policy\":{\"createdAt\":\"2023-09-08T19:49:00.583680Z\",\"guardians\":[{\"label\":\"Guardian 1\",\"participantId\":\"A8f12d5c6d25A06bC5fDC3Da0f48e5b2B08Fa8B15634E4d6adDbDFb655cc8572\",\"status\":{\"type\":\"Accepted\",\"deviceEncryptedShard\":\"Z3VhcmRpYW4gMSBzaGFyZA==\",\"signature\":\"MEUCIQCwwzJH+GAKLYEza7CNSsBMdjuSK/5KsoQmMwlJ/a8lfAIgCczm1m4oUKyjVae1Mik4Raf73kz5sOPdrFarBuLrPfI=\",\"timeMillis\":1694202540923,\"guardianTransportPublicKey\":\"rVKpXLwFgWCzhNo9BNZ9k6gBkSF6Hek5GRDaSXFNojMH\",\"acceptedAt\":\"2023-09-08T19:49:00.973434Z\"}},{\"label\":\"Guardian 2\",\"participantId\":\"A5d4818C56E0DfFAc2bBbDabbeEA5571A94a87e5D9E0fC0bAB314fCe7a05Bcc7\",\"status\":{\"type\":\"Invited\",\"deviceEncryptedShard\":\"Z3VhcmRpYW4gMiBzaGFyZA==\",\"deviceEncryptedPin\":\"BGHuWzNzSdo/n+/d9b769Ff90elTeprufl8qa9tafO9ivC4H/g5uPMPhJBIUrZy5ePrYktkKwdBmX/GOh3E1ePVVxUGRRH8W46sl7NFqM73KlMDO78cy\",\"invitedAt\":\"2023-09-08T19:49:00.814970Z\"}},{\"label\":\"Guardian 3\",\"participantId\":\"85727a62Bf5eaCdC0EBEa8C58e716C4Adf6f5Aa65516BA7CABE6A2f685347EDF\",\"status\":{\"type\":\"Invited\",\"deviceEncryptedShard\":\"Z3VhcmRpYW4gMyBzaGFyZA==\",\"deviceEncryptedPin\":\"BB/17KibPmXjlcAY3J42uYi4E0SjmTnAuaIfmNNDGuEwYxaSGqD6bChw/I1j2Gb5da7cFbsRRA8jdcECdt+Y3WqBysb/CylkRTpSvhezV1q6qudQp5RM\",\"invitedAt\":\"2023-09-08T19:49:00.894645Z\"}}],\"threshold\":2,\"encryptedMasterKey\":\"BOacnUfXgT20xiS7pTjR+xp7l8SdJYh3RUsxYQ+QXO8GPBD3zn81R+7IE9YwfMB5sPTNa9i2yTK8+2oMPxc7y+fVyouuUSv9cwiwogMmw4CIHf/6pkB1VS4rbAuZBNPky6eSTwwQx3U/Wl4nE1lN+rbw\",\"intermediateKey\":\"2BEt8X9pZM6QMspqZ1NTXZoq1NxpYHshBJMMiSaxWWso2\"},\"publicMasterEncryptionKey\":\"tzhMpeW9dXeUv7vETy6ZU18ZkLSwbUkxbX3DaJC6Cdy1\"},\"biometricVerificationRequired\":false}"
        
        let confirmed = "{\"contacts\":[{\"identifier\":\"contact_01h9v5ec4qeds80c4k13zh73xj\",\"contactType\":\"Email\",\"value\":\"9b990f03-4917-469c-9174-93f34165dae8@test.com\",\"verified\":true},{\"identifier\":\"contact_01h9v5ec8de1h9yw144q7gmk92\",\"contactType\":\"Phone\",\"value\":\"+1726890397\",\"verified\":true}],\"ownerState\":{\"type\":\"PolicySetup\",\"policy\":{\"createdAt\":\"2023-09-08T19:49:00.583680Z\",\"guardians\":[{\"label\":\"Guardian 1\",\"participantId\":\"A8f12d5c6d25A06bC5fDC3Da0f48e5b2B08Fa8B15634E4d6adDbDFb655cc8572\",\"status\":{\"type\":\"Confirmed\",\"guardianTransportEncryptedShard\":\"BMK/Eb+7PzLZiCYUryWKeGitjivh5PgtFOxVBY+2tiLKyj4ZpMOmp2Sok3kE6i3YSLXgivgExMXvqqBEpFpiPu4NDKNjFw4ePeTN0nsm0g1/EVR/WNE=\",\"confirmedAt\":\"2023-09-08T19:49:01.068839Z\"}},{\"label\":\"Guardian 2\",\"participantId\":\"A5d4818C56E0DfFAc2bBbDabbeEA5571A94a87e5D9E0fC0bAB314fCe7a05Bcc7\",\"status\":{\"type\":\"Invited\",\"deviceEncryptedShard\":\"Z3VhcmRpYW4gMiBzaGFyZA==\",\"deviceEncryptedPin\":\"BGHuWzNzSdo/n+/d9b769Ff90elTeprufl8qa9tafO9ivC4H/g5uPMPhJBIUrZy5ePrYktkKwdBmX/GOh3E1ePVVxUGRRH8W46sl7NFqM73KlMDO78cy\",\"invitedAt\":\"2023-09-08T19:49:00.814970Z\"}},{\"label\":\"Guardian 3\",\"participantId\":\"85727a62Bf5eaCdC0EBEa8C58e716C4Adf6f5Aa65516BA7CABE6A2f685347EDF\",\"status\":{\"type\":\"Invited\",\"deviceEncryptedShard\":\"Z3VhcmRpYW4gMyBzaGFyZA==\",\"deviceEncryptedPin\":\"BB/17KibPmXjlcAY3J42uYi4E0SjmTnAuaIfmNNDGuEwYxaSGqD6bChw/I1j2Gb5da7cFbsRRA8jdcECdt+Y3WqBysb/CylkRTpSvhezV1q6qudQp5RM\",\"invitedAt\":\"2023-09-08T19:49:00.894645Z\"}}],\"threshold\":2,\"encryptedMasterKey\":\"BOacnUfXgT20xiS7pTjR+xp7l8SdJYh3RUsxYQ+QXO8GPBD3zn81R+7IE9YwfMB5sPTNa9i2yTK8+2oMPxc7y+fVyouuUSv9cwiwogMmw4CIHf/6pkB1VS4rbAuZBNPky6eSTwwQx3U/Wl4nE1lN+rbw\",\"intermediateKey\":\"2BEt8X9pZM6QMspqZ1NTXZoq1NxpYHshBJMMiSaxWWso2\"},\"publicMasterEncryptionKey\":\"tzhMpeW9dXeUv7vETy6ZU18ZkLSwbUkxbX3DaJC6Cdy1\"},\"biometricVerificationRequired\":false}"
        
        let onboarded = "{\"contacts\":[{\"identifier\":\"contact_01h9v5ec4qeds80c4k13zh73xj\",\"contactType\":\"Email\",\"value\":\"9b990f03-4917-469c-9174-93f34165dae8@test.com\",\"verified\":true},{\"identifier\":\"contact_01h9v5ec8de1h9yw144q7gmk92\",\"contactType\":\"Phone\",\"value\":\"+1726890397\",\"verified\":true}],\"ownerState\":{\"type\":\"PolicySetup\",\"policy\":{\"createdAt\":\"2023-09-08T19:49:00.583680Z\",\"guardians\":[{\"label\":\"Guardian 1\",\"participantId\":\"A8f12d5c6d25A06bC5fDC3Da0f48e5b2B08Fa8B15634E4d6adDbDFb655cc8572\",\"status\":{\"type\":\"Onboarded\",\"guardianEncryptedData\":\"BGHuWzNzSdo/n+/d9b769Ff90elTeprufl8qa9tafO9ivC4H/g5uPMPhJBI\",\"passwordHash\":\"12345\",\"createdAt\":\"2023-09-08T19:49:01.146348Z\"}},{\"label\":\"Guardian 2\",\"participantId\":\"A5d4818C56E0DfFAc2bBbDabbeEA5571A94a87e5D9E0fC0bAB314fCe7a05Bcc7\",\"status\":{\"type\":\"Invited\",\"deviceEncryptedShard\":\"Z3VhcmRpYW4gMiBzaGFyZA==\",\"deviceEncryptedPin\":\"BGHuWzNzSdo/n+/d9b769Ff90elTeprufl8qa9tafO9ivC4H/g5uPMPhJBIUrZy5ePrYktkKwdBmX/GOh3E1ePVVxUGRRH8W46sl7NFqM73KlMDO78cy\",\"invitedAt\":\"2023-09-08T19:49:00.814970Z\"}},{\"label\":\"Guardian 3\",\"participantId\":\"85727a62Bf5eaCdC0EBEa8C58e716C4Adf6f5Aa65516BA7CABE6A2f685347EDF\",\"status\":{\"type\":\"Invited\",\"deviceEncryptedShard\":\"Z3VhcmRpYW4gMyBzaGFyZA==\",\"deviceEncryptedPin\":\"BB/17KibPmXjlcAY3J42uYi4E0SjmTnAuaIfmNNDGuEwYxaSGqD6bChw/I1j2Gb5da7cFbsRRA8jdcECdt+Y3WqBysb/CylkRTpSvhezV1q6qudQp5RM\",\"invitedAt\":\"2023-09-08T19:49:00.894645Z\"}}],\"threshold\":2,\"encryptedMasterKey\":\"BOacnUfXgT20xiS7pTjR+xp7l8SdJYh3RUsxYQ+QXO8GPBD3zn81R+7IE9YwfMB5sPTNa9i2yTK8+2oMPxc7y+fVyouuUSv9cwiwogMmw4CIHf/6pkB1VS4rbAuZBNPky6eSTwwQx3U/Wl4nE1lN+rbw\",\"intermediateKey\":\"2BEt8X9pZM6QMspqZ1NTXZoq1NxpYHshBJMMiSaxWWso2\"},\"publicMasterEncryptionKey\":\"tzhMpeW9dXeUv7vETy6ZU18ZkLSwbUkxbX3DaJC6Cdy1\"},\"biometricVerificationRequired\":false}"
        
        let ready = "{\"contacts\":[{\"identifier\":\"contact_01h9v5ec4qeds80c4k13zh73xj\",\"contactType\":\"Email\",\"value\":\"9b990f03-4917-469c-9174-93f34165dae8@test.com\",\"verified\":true},{\"identifier\":\"contact_01h9v5ec8de1h9yw144q7gmk92\",\"contactType\":\"Phone\",\"value\":\"+1726890397\",\"verified\":true}],\"ownerState\":{\"type\":\"Ready\",\"policy\":{\"createdAt\":\"2023-09-08T19:49:00.583680Z\",\"guardians\":[{\"label\":\"Guardian 1\",\"participantId\":\"A8f12d5c6d25A06bC5fDC3Da0f48e5b2B08Fa8B15634E4d6adDbDFb655cc8572\",\"attributes\":{\"guardianEncryptedData\":\"BGHuWzNzSdo/n+/d9b769Ff90elTeprufl8qa9tafO9ivC4H/g5uPMPhJBI\",\"passwordHash\":\"12345\",\"createdAt\":\"2023-09-08T19:49:00.586902Z\"}},{\"label\":\"Guardian 2\",\"participantId\":\"A5d4818C56E0DfFAc2bBbDabbeEA5571A94a87e5D9E0fC0bAB314fCe7a05Bcc7\",\"attributes\":{\"guardianEncryptedData\":\"\",\"passwordHash\":\"\",\"createdAt\":\"2023-09-08T19:49:00.586968Z\"}},{\"label\":\"Guardian 3\",\"participantId\":\"85727a62Bf5eaCdC0EBEa8C58e716C4Adf6f5Aa65516BA7CABE6A2f685347EDF\",\"attributes\":{\"guardianEncryptedData\":\"\",\"passwordHash\":\"\",\"createdAt\":\"2023-09-08T19:49:00.587032Z\"}}],\"threshold\":2,\"encryptedMasterKey\":\"BOacnUfXgT20xiS7pTjR+xp7l8SdJYh3RUsxYQ+QXO8GPBD3zn81R+7IE9YwfMB5sPTNa9i2yTK8+2oMPxc7y+fVyouuUSv9cwiwogMmw4CIHf/6pkB1VS4rbAuZBNPky6eSTwwQx3U/Wl4nE1lN+rbw\",\"intermediateKey\":\"2BEt8X9pZM6QMspqZ1NTXZoq1NxpYHshBJMMiSaxWWso2\"},\"vault\":{\"secrets\":[],\"publicMasterEncryptionKey\":\"tzhMpeW9dXeUv7vETy6ZU18ZkLSwbUkxbX3DaJC6Cdy1\"}},\"biometricVerificationRequired\":false}"
        
        
        let noOwnerStateResponse: API.User = JsonParser.decodeJsonType(data: noOwnerState.data(using: .utf8)!)
        XCTAssertNil(noOwnerStateResponse.ownerState)
        
        let initialResponse: API.User = JsonParser.decodeJsonType(data: initial.data(using: .utf8)!)
        switch (initialResponse.ownerState) {
        case .policySetup(let policySetup):
            XCTAssertEqual("123", policySetup.publicMasterEncryptionKey)
            XCTAssertEqual(
                "BBz7rf1BzCAHgWpum12atRCzxiMW8QI98pVofDYNcO0k0f5SmZCIIndeL4NVXtl+DEi8ub6KYFWjDQsBqNgLe83kdM5AsR9Og77i5PO5Zwpj0ULQpRdCgt1XT5oFpW5Vwof07IBEXS9yFtVzOUcZ/oa3",
                policySetup.policy.encryptedMasterKey
            )
            XCTAssertEqual(
                "dFeEDwhgYbAA2Jzrsk5N8ahzzQyCpEELUbECaai8L6fM",
                policySetup.policy.intermediateKey
            )
            XCTAssertEqual("123",
                           policySetup.publicMasterEncryptionKey
            )
            XCTAssertEqual(2, policySetup.policy.threshold)
            XCTAssertEqual(3, policySetup.policy.guardians.count)
            let firstGuardian = (policySetup.policy.guardians[0] as API.PolicyGuardian.ProspectGuardian)
            XCTAssertEqual("Guardian 1", firstGuardian.label)
            XCTAssertEqual("D570761fFc2ad9AFeeDcA2Bee23Facf1Ed4caD89Ba48e4dAEb1eCEdAa6eEC76D", firstGuardian.participantId)
            switch (firstGuardian.status) {
            case .initial(let status):
                XCTAssertEqual("Z3VhcmRpYW4gMSBzaGFyZA==", status.deviceEncryptedShard)
            default:
                XCTFail("Invalid Guardian Status")
            }
        default:
            XCTFail("Should not get here")
        }
        
        let invitedResponse: API.User = JsonParser.decodeJsonType(data: invited.data(using: .utf8)!)
        switch (invitedResponse.ownerState) {
        case .policySetup(let policySetup):
            let firstGuardian = (policySetup.policy.guardians[0] as API.PolicyGuardian.ProspectGuardian)
            switch (firstGuardian.status) {
            case .invited(let status):
                XCTAssertEqual(
                    "BHcKE1Nn+lrQB62VkZPCj/DjbVk6fa8V73w4w6FS1DtBJeYxnJzCtYgt6wRerAfFPcqizzPiF38hUegReyF0vSbohWPDexjCtp4VPEkuA2D6hsfR/U4m",
                    status.deviceEncryptedPin
                )
                XCTAssertEqual("Z3VhcmRpYW4gMSBzaGFyZA==", status.deviceEncryptedShard)
            default:
                XCTFail("Invalid Guardian Status")
            }
        default:
            XCTFail("Should not get here")
        }
        
        let acceptedResponse: API.User = JsonParser.decodeJsonType(data: accepted.data(using: .utf8)!)
        switch (acceptedResponse.ownerState) {
        case .policySetup(let policySetup):
            let firstGuardian = (policySetup.policy.guardians[0] as API.PolicyGuardian.ProspectGuardian)
            switch (firstGuardian.status) {
            case .accepted(let status):
                XCTAssertEqual("rVKpXLwFgWCzhNo9BNZ9k6gBkSF6Hek5GRDaSXFNojMH", status.guardianTransportPublicKey)
                XCTAssertEqual("Z3VhcmRpYW4gMSBzaGFyZA==", status.deviceEncryptedShard)
                XCTAssertEqual("MEUCIQCwwzJH+GAKLYEza7CNSsBMdjuSK/5KsoQmMwlJ/a8lfAIgCczm1m4oUKyjVae1Mik4Raf73kz5sOPdrFarBuLrPfI=", status.signature)
                XCTAssertEqual(1694202540923, status.timeMillis)
            default:
                XCTFail("Invalid Guardian Status")
            }
        default:
            XCTFail("Should not get here")
        }
        
        let confirmedResponse: API.User = JsonParser.decodeJsonType(data: confirmed.data(using: .utf8)!)
        switch (confirmedResponse.ownerState) {
        case .policySetup(let policySetup):
            let firstGuardian = (policySetup.policy.guardians[0] as API.PolicyGuardian.ProspectGuardian)
            switch (firstGuardian.status) {
            case .confirmed(let status):
                XCTAssertEqual(
                    "BMK/Eb+7PzLZiCYUryWKeGitjivh5PgtFOxVBY+2tiLKyj4ZpMOmp2Sok3kE6i3YSLXgivgExMXvqqBEpFpiPu4NDKNjFw4ePeTN0nsm0g1/EVR/WNE=",
                    status.guardianTransportEncryptedShard
                )
            default:
                XCTFail("Invalid Guardian Status")
            }
        default:
            XCTFail("Should not get here")
        }
        
        let onboardedResponse: API.User = JsonParser.decodeJsonType(data: onboarded.data(using: .utf8)!)
        switch (onboardedResponse.ownerState) {
        case .policySetup(let policySetup):
            let firstGuardian = (policySetup.policy.guardians[0] as API.PolicyGuardian.ProspectGuardian)
            switch (firstGuardian.status) {
            case .onboarded(let status):
                XCTAssertEqual(
                    "BGHuWzNzSdo/n+/d9b769Ff90elTeprufl8qa9tafO9ivC4H/g5uPMPhJBI",
                    status.guardianEncryptedData
                )
                XCTAssertEqual(
                    "12345",
                    status.passwordHash
                )
            default:
                XCTFail("Invalid Guardian Status")
            }
        default:
            XCTFail("Should not get here")
        }
        
        let readyResponse: API.User = JsonParser.decodeJsonType(data: ready.data(using: .utf8)!)
        switch (readyResponse.ownerState) {
        case .ready(let ready):
            XCTAssertEqual(
                "tzhMpeW9dXeUv7vETy6ZU18ZkLSwbUkxbX3DaJC6Cdy1",
                ready.vault.publicMasterEncryptionKey
            )
            XCTAssertEqual([], ready.vault.secrets)
            let firstGuardian = ready.policy.guardians[0]
            XCTAssertEqual("Guardian 1", firstGuardian.label)
            XCTAssertEqual(
                "A8f12d5c6d25A06bC5fDC3Da0f48e5b2B08Fa8B15634E4d6adDbDFb655cc8572",
                firstGuardian.participantId
            )
            XCTAssertEqual(
                "BGHuWzNzSdo/n+/d9b769Ff90elTeprufl8qa9tafO9ivC4H/g5uPMPhJBI",
                firstGuardian.attributes.guardianEncryptedData
            )
            XCTAssertEqual(
                "12345",
                firstGuardian.attributes.passwordHash
            )
        default:
            XCTFail("Should not get here")
        }
    }
}
