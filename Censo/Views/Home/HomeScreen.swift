//
//  HomeScreen.swift
//
//  Created by Anton Onyshchenko on 29.09.23.
//

import Foundation
import SwiftUI
import UIKit
import Moya

struct HomeScreen: View {
    var session: Session
    var ownerState: API.OwnerState.Ready
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    
    enum TabId {
        case dashboard
        case phrases
        case settings
    }
    
    @State private var selectedTab = TabId.dashboard
                    
    var body: some View {
        VStack {
            Spacer()
            TabView(selection: $selectedTab) {
                VStack {
                    DashboardTab(
                        session: session,
                        ownerState: ownerState,
                        onOwnerStateUpdated: onOwnerStateUpdated,
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
                    PhrasesTab(
                        session: session,
                        ownerState: ownerState,
                        onOwnerStateUpdated: onOwnerStateUpdated
                    )
                    tabDivider()
                }
                .tabItem {
                    VStack {
                        Text("My Phrases")
                        Image("LockClosed").renderingMode(.template)
                    }
                }
                .tag(TabId.phrases)
                
                VStack {
                    SettingsTab(
                        session: session,
                        ownerState: ownerState,
                        onOwnerStateUpdated: onOwnerStateUpdated
                    )
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
        .padding(.vertical)
    }
    
    private func tabDivider() -> some View {
        VStack {
            Spacer()
            Divider().padding(.bottom, 20)
        }.frame(height: 30)
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
}

extension API.Vault {
    static var sample: Self {
        .init(
            seedPhrases: [.sample, .sample2, .sample3],
            publicMasterEncryptionKey: try! Base58EncodedPublicKey(value: "PQVchxggKG9sQRNx9Yi6Yu5gSCeLQFmxuCzmx1zmNBdRVoCTPeab1F612GE4N7UZezqGBDYUB25yGuFzWsob9wY2")
        )
    }
}

extension API.SeedPhrase {
    static var sample: Self {
        .init(guid: "guid1", encryptedSeedPhrase: .sample, seedPhraseHash: .sample, label: "Yankee Hotel Foxtrot", createdAt: Date())
    }
    static var sample2: Self {
        .init(guid: "guid2", encryptedSeedPhrase: .sample, seedPhraseHash: .sample, label: "Robin Hood", createdAt: Date())
    }
    static var sample3: Self {
        .init(guid: "guid3", encryptedSeedPhrase: .sample, seedPhraseHash: .sample, label: "SEED PHRASE WITH A VERY LONG NAME OF 50 CHARACTERS", createdAt: Date())
    }
}

struct CensoHomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen(
            session: .sample,
            ownerState: API.OwnerState.Ready(
                policy: .sample,
                vault: .sample,
                access: nil,
                authType: .facetec,
                subscriptionStatus: .active
            ),
            onOwnerStateUpdated: { _ in }
        )
        
        HomeScreen(
            session: .sample,
            ownerState: API.OwnerState.Ready(
                policy: .sample2Approvers,
                vault: .sample,
                access: nil,
                authType: .facetec,
                subscriptionStatus: .active
            ),
            onOwnerStateUpdated: { _ in }
        )
    }
}
#endif
