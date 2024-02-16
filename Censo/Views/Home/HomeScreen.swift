//
//  HomeScreen.swift
//
//  Created by Anton Onyshchenko on 29.09.23.
//

import Foundation
import SwiftUI
import UIKit

struct HomeScreen: View {
    var ownerState: API.OwnerState.Ready
    
    @ObservedObject var featureFlagState = FeatureFlagState.shared
    
    enum TabId {
        case dashboard
        case phrases
        case settings
        case legacy
    }
    
    @State private var selectedTab = TabId.dashboard
    
    init(ownerState: API.OwnerState.Ready, featureFlagState: FeatureFlagState = FeatureFlagState.shared) {
        self.ownerState = ownerState
        self.featureFlagState = featureFlagState
        
        let standardTabBarAppearence = UITabBarAppearance.init(idiom: .phone)
        standardTabBarAppearence.configureWithTransparentBackground()
        UITabBar.appearance().standardAppearance = standardTabBarAppearence
        
        let scrollEdgeTabBarAppearance = UITabBarAppearance.init(idiom: .phone)
        scrollEdgeTabBarAppearance.configureWithTransparentBackground()
        UITabBar.appearance().scrollEdgeAppearance = scrollEdgeTabBarAppearance
    }
                    
    var body: some View {
        VStack {
            Spacer()
            TabView(selection: $selectedTab) {
                VStack {
                    DashboardTab(
                        ownerState: ownerState,
                        parentTabViewSelectedTab: $selectedTab
                    )
                    tabDivider()
                }
                .tabItem {
                    VStack {
                        Text("Home")
                        Image("HomeFilled").renderingMode(.template)
                    }
                }
                .tag(TabId.dashboard)
                    
                VStack {
                    PhrasesTab(ownerState: ownerState)
                    tabDivider()
                }
                .tabItem {
                    VStack {
                        Text("My Phrases")
                        Image("LockClosed").renderingMode(.template)
                    }
                }
                .tag(TabId.phrases)
                
                if featureFlagState.legacyEnabled() {
                    VStack(spacing: 0) {
                        LegacyTab(ownerState: ownerState)
                        tabDivider()
                    }
                    .tabItem {
                        VStack {
                            Text("Legacy")
                            Image("LegacyTab").renderingMode(.template)
                        }
                    }
                    .tag(TabId.legacy)
                }
                
                VStack(spacing: 0) {
                    SettingsTab(ownerState: .ready(ownerState))
                    tabDivider()
                }
                .tabItem {
                    VStack {
                        Text("Settings")
                        Image("SettingsFilled").renderingMode(.template)
                    }
                }
                .tag(TabId.settings)
            }
            .accentColor(.Censo.primaryForeground)
        }
        .padding(.top)
        .padding(.bottom, 2)
    }
    
    private func tabDivider() -> some View {
        VStack(spacing: 0) {
            Divider().padding(.bottom, 2)
        }
    }
}



#if DEBUG
extension API.TrustedApprover {
    static var sample: Self {
        .init(
            label: "Ben",
            participantId: ParticipantId(bigInt: generateParticipantId()),
            isOwner: false,
            attributes: API.TrustedApprover.Attributes(
                onboardedAt: Date()
            )
        )
    }
    static var sample2: Self {
        .init(
            label: "Brendan",
            participantId: ParticipantId(bigInt: generateParticipantId()),
            isOwner: false,
            attributes: API.TrustedApprover.Attributes(
                onboardedAt: Date()
            )
        )
    }
    static var sample3: Self {
        .init(
            label: "Ievgen",
            participantId: ParticipantId(bigInt: generateParticipantId()),
            isOwner: false,
            attributes: API.TrustedApprover.Attributes(
                onboardedAt: Date()
            )
        )
    }
    
    static var sample4: Self {
        .init(
            label: "Ata",
            participantId: ParticipantId(bigInt: generateParticipantId()),
            isOwner: false,
            attributes: API.TrustedApprover.Attributes(
                onboardedAt: Date()
            )
        )
    }
    
    static var sample5: Self {
        .init(
            label: "Sam",
            participantId: ParticipantId(bigInt: generateParticipantId()),
            isOwner: false,
            attributes: API.TrustedApprover.Attributes(
                onboardedAt: Date()
            )
        )
    }
    
    static var sampleOwner: Self {
        .init(
            label: "Me",
            participantId: ParticipantId(bigInt: generateParticipantId()),
            isOwner: true,
            attributes: API.TrustedApprover.Attributes(
                onboardedAt: Date()
            )
        )
    }
}

extension API.Policy {
    static var sample: Self {
        .init(
            createdAt: Date(),
            approvers: [.sampleOwner],
            threshold: 1,
            encryptedMasterKey: Base64EncodedString(data: Data()),
            intermediateKey: try! Base58EncodedPublicKey(value: "PQVchxggKG9sQRNx9Yi6Yu5gSCeLQFmxuCzmx1zmNBdRVoCTPeab1F612GE4N7UZezqGBDYUB25yGuFzWsob9wY2"), 
            approverKeysSignatureByIntermediateKey: Base64EncodedString(data: Data())
        )
    }
    
    static var sample2Approvers: Self {
        .init(
            createdAt: Date(),
            approvers: [.sample, .sample2],
            threshold: 2,
            encryptedMasterKey: Base64EncodedString(data: Data()),
            intermediateKey: try! Base58EncodedPublicKey(value: "PQVchxggKG9sQRNx9Yi6Yu5gSCeLQFmxuCzmx1zmNBdRVoCTPeab1F612GE4N7UZezqGBDYUB25yGuFzWsob9wY2"),
            approverKeysSignatureByIntermediateKey: Base64EncodedString(data: Data())
        )
    }
    
    static var sample2ApproversAndBeneficiary: Self {
        .init(
            createdAt: Date(),
            approvers: [.sample, .sample2],
            threshold: 2,
            encryptedMasterKey: Base64EncodedString(data: Data()),
            intermediateKey: try! Base58EncodedPublicKey(value: "PQVchxggKG9sQRNx9Yi6Yu5gSCeLQFmxuCzmx1zmNBdRVoCTPeab1F612GE4N7UZezqGBDYUB25yGuFzWsob9wY2"),
            approverKeysSignatureByIntermediateKey: Base64EncodedString(data: Data()),
            beneficiary: .sample
        )
    }
    
    static var sample2ApproversAndAcceptedBeneficiary: Self {
        .init(
            createdAt: Date(),
            approvers: [.sample, .sample2],
            threshold: 2,
            encryptedMasterKey: Base64EncodedString(data: Data()),
            intermediateKey: try! Base58EncodedPublicKey(value: "PQVchxggKG9sQRNx9Yi6Yu5gSCeLQFmxuCzmx1zmNBdRVoCTPeab1F612GE4N7UZezqGBDYUB25yGuFzWsob9wY2"),
            approverKeysSignatureByIntermediateKey: Base64EncodedString(data: Data()),
            ownerEntropy: Base64EncodedString(data: "test".data(using: .utf8)!),
            beneficiary: .sampleAccepted
        )
    }
    
}

extension API.TimelockSetting {
    static var sample: Self {
        .init(defaultTimelockInSeconds: 172800, currentTimelockInSeconds: nil)
    }
    
    static var sample2: Self {
        .init(defaultTimelockInSeconds: 172800, currentTimelockInSeconds: 172800)
    }
    
    static var sample3: Self {
        .init(defaultTimelockInSeconds: 172800,
              currentTimelockInSeconds: 172800,
              disabledAt: Date().addingTimeInterval(60000)
        )
    }
}

extension API.Vault {
    static var samplePublicMasterEncryptionKey = try! Base58EncodedPublicKey(value: "PQVchxggKG9sQRNx9Yi6Yu5gSCeLQFmxuCzmx1zmNBdRVoCTPeab1F612GE4N7UZezqGBDYUB25yGuFzWsob9wY2")
    
    static var sample: Self {
        .init(
            seedPhrases: [.sample, .sample2, .sample3, .sample4, .sample5],
            publicMasterEncryptionKey: samplePublicMasterEncryptionKey
        )
    }
    static var sample1Phrase: Self {
        .init(
            seedPhrases: [.sample],
            publicMasterEncryptionKey: samplePublicMasterEncryptionKey
        )
    }
}

extension API.SeedPhrase {
    static var sample: Self {
        .init(guid: "guid1", seedPhraseHash: .sample, label: "Yankee Hotel Foxtrot", type: .binary, createdAt: Date())
    }
    static var sampleWithNotes: Self {
        .init(guid: "guid1", seedPhraseHash: .sample, label: "Yankee Hotel Foxtrot", type: .binary,
              encryptedNotes: API.SeedPhraseEncryptedNotes(
                ownerApproverKeyEncryptedText: try! Base64EncodedString(value: ""),
                masterKeyEncryptedText: try! Base64EncodedString(value: "")
              ),
              createdAt: Date()
        )
    }
    static var sample2: Self {
        .init(guid: "guid2", seedPhraseHash: .sample, label: "Robin Hood", type: .binary, createdAt: Date())
    }
    static var sample3: Self {
        .init(guid: "guid3", seedPhraseHash: .sample, label: "SEED PHRASE WITH A VERY LONG NAME OF 50 CHARACTERS", type: .photo, createdAt: Date())
    }
    static var sample4: Self {
        .init(guid: "guid4", seedPhraseHash: .sample, label: "Wallet 1", type: .binary, createdAt: Date())
    }
    static var sample5: Self {
        .init(guid: "guid5", seedPhraseHash: .sample, label: "Wallet 2", type: .binary, createdAt: Date())
    }
}

#Preview("NoApproversWithLegacy") {
    LoggedInOwnerPreviewContainer {
        HomeScreen(
            ownerState: API.OwnerState.Ready(
                policy: .sample,
                vault: .sample,
                access: nil,
                authType: .facetec,
                subscriptionStatus: .active,
                timelockSetting: .sample,
                subscriptionRequired: true,
                onboarded: true,
                canRequestAuthenticationReset: false
            ),
            featureFlagState: FeatureFlagState(["legacy"])
        )
    }
}

#Preview("ApproversWithLegacy") {
    LoggedInOwnerPreviewContainer {
        HomeScreen(
            ownerState: API.OwnerState.Ready(
                policy: .sample2Approvers,
                vault: .sample,
                access: nil,
                authType: .facetec,
                subscriptionStatus: .active,
                timelockSetting: .sample,
                subscriptionRequired: true,
                onboarded: true,
                canRequestAuthenticationReset: false
            ),
            featureFlagState: FeatureFlagState(["legacy"])
        )
    }
}

#Preview("TimelockedAccess") {
    LoggedInOwnerPreviewContainer {
        HomeScreen(
            ownerState: API.OwnerState.Ready(
                policy: .sample2Approvers,
                vault: .sample,
                access: .thisDevice(API.Access.ThisDevice(
                    guid: "",
                    status: API.Access.Status.timelocked,
                    createdAt: Date(),
                    unlocksAt: Date().addingTimeInterval(7200),
                    expiresAt: Date(),
                    approvals: [],
                    intent: .accessPhrases
                )),
                authType: .facetec,
                subscriptionStatus: .active,
                timelockSetting: .sample,
                subscriptionRequired: true,
                onboarded: true,
                canRequestAuthenticationReset: false
            )
        )
    }
}
#Preview("AvailableAccess") {
    LoggedInOwnerPreviewContainer {
        HomeScreen(
            ownerState: API.OwnerState.Ready(
                policy: .sample2Approvers,
                vault: .sample,
                access: .thisDevice(API.Access.ThisDevice(
                    guid: "",
                    status: API.Access.Status.available,
                    createdAt: Date(),
                    unlocksAt: Date().addingTimeInterval(7200),
                    expiresAt: Date(),
                    approvals: [],
                    intent: .accessPhrases
                )),
                authType: .facetec,
                subscriptionStatus: .active,
                timelockSetting: .sample,
                subscriptionRequired: true,
                onboarded: true,
                canRequestAuthenticationReset: false
            )
        )
    }
}
#endif
