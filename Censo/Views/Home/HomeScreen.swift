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
    //var onUserReset: () -> Void
    
    enum TabId {
        case dashboard
        case phrases
        case approvers
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
                        Image("SimpleHomeGray").renderingMode(.template)
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
                        Text("Phrases")
                        Image("LockSimpleGray").renderingMode(.template)
                    }
                }
                .tag(TabId.phrases)
                
                VStack {
                    ApproversTab(
                        session: session,
                        ownerState: ownerState,
                        onOwnerStateUpdated: onOwnerStateUpdated
                    )
                    tabDivider()
                }
                .tabItem {
                    VStack {
                        Text("Approvers")
                        Image("TwoUsersGray").renderingMode(.template)
                    }
                }
                .tag(TabId.approvers)
                
                VStack {
                    SettingsTab(
                        session: session,
                        onOwnerStateUpdated: onOwnerStateUpdated
                    )
                    tabDivider()
                }
                .tabItem {
                    VStack {
                        Text("Settings")
                        Image("SettingsGray").renderingMode(.template)
                    }
                }
                .tag(TabId.settings)
            }
            .accentColor(.black)
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
extension API.TrustedGuardian {
    static var sample: Self {
        .init(
            label: "Ben",
            participantId: ParticipantId(bigInt: generateParticipantId()),
            isOwner: false,
            attributes: API.TrustedGuardian.Attributes(
                onboardedAt: Date()
            )
        )
    }
    static var sample2: Self {
        .init(
            label: "Brendan",
            participantId: ParticipantId(bigInt: generateParticipantId()),
            isOwner: false,
            attributes: API.TrustedGuardian.Attributes(
                onboardedAt: Date()
            )
        )
    }
    static var sample3: Self {
        .init(
            label: "Ievgen",
            participantId: ParticipantId(bigInt: generateParticipantId()),
            isOwner: false,
            attributes: API.TrustedGuardian.Attributes(
                onboardedAt: Date()
            )
        )
    }
    
    static var sample4: Self {
        .init(
            label: "Ata",
            participantId: ParticipantId(bigInt: generateParticipantId()),
            isOwner: false,
            attributes: API.TrustedGuardian.Attributes(
                onboardedAt: Date()
            )
        )
    }
    
    static var sample5: Self {
        .init(
            label: "Sam",
            participantId: ParticipantId(bigInt: generateParticipantId()),
            isOwner: false,
            attributes: API.TrustedGuardian.Attributes(
                onboardedAt: Date()
            )
        )
    }
    
    static var sampleOwner: Self {
        .init(
            label: "Me",
            participantId: ParticipantId(bigInt: generateParticipantId()),
            isOwner: true,
            attributes: API.TrustedGuardian.Attributes(
                onboardedAt: Date()
            )
        )
    }
}

extension API.Policy {
    static var sample: Self {
        .init(
            createdAt: Date(),
            guardians: [.sample],
            threshold: 2,
            encryptedMasterKey: Base64EncodedString(data: Data()),
            intermediateKey: try! Base58EncodedPublicKey(value: "PQVchxggKG9sQRNx9Yi6Yu5gSCeLQFmxuCzmx1zmNBdRVoCTPeab1F612GE4N7UZezqGBDYUB25yGuFzWsob9wY2")
        )
    }
    
    static var sample2Approvers: Self {
        .init(
            createdAt: Date(),
            guardians: [.sample, .sample2],
            threshold: 2,
            encryptedMasterKey: Base64EncodedString(data: Data()),
            intermediateKey: try! Base58EncodedPublicKey(value: "PQVchxggKG9sQRNx9Yi6Yu5gSCeLQFmxuCzmx1zmNBdRVoCTPeab1F612GE4N7UZezqGBDYUB25yGuFzWsob9wY2")
        )
    }
}

extension API.Vault {
    static var sample: Self {
        .init(
            secrets: [.sample, .sample2, .sample3],
            publicMasterEncryptionKey: try! Base58EncodedPublicKey(value: "PQVchxggKG9sQRNx9Yi6Yu5gSCeLQFmxuCzmx1zmNBdRVoCTPeab1F612GE4N7UZezqGBDYUB25yGuFzWsob9wY2")
        )
    }
}

extension API.VaultSecret {
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
                recovery: nil
            ),
            onOwnerStateUpdated: { _ in }
        )
    }
}
#endif
