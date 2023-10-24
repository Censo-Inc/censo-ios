//
//  VaultHomeScreen.swift
//  Vault
//
//  Created by Anton Onyshchenko on 29.09.23.
//

import Foundation
import SwiftUI
import UIKit
import Moya

struct VaultHomeScreen: View {
    
    var session: Session
    var ownerState: API.OwnerState.Ready
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    //var onUserReset: () -> Void
    
    enum TabName {
        case home
        case phrases
        case approvers
        case settings
    }
    
    @State private var selectedTab = TabName.home
                    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(
                session: session,
                ownerState: ownerState,
                onOwnerStateUpdated: onOwnerStateUpdated,
                parentTabViewSelectedTab: $selectedTab
            )
            .tabItem {
                VStack {
                    Text("Home")
                    Image("SimpleHomeGray").renderingMode(.template)
                }
            }
            .tag(TabName.home)
            
            PhrasesView(
                session: session,
                ownerState: ownerState,
                onOwnerStateUpdated: onOwnerStateUpdated
            )
            .tabItem {
                VStack {
                    Text("Phrases")
                    Image("LockSimpleGray").renderingMode(.template)
                }
            }
            .tag(TabName.phrases)
            
            ApproversView(
                session: session,
                ownerState: ownerState,
                onOwnerStateUpdated: onOwnerStateUpdated
            )
            .tabItem {
                VStack {
                    Text("Approvers")
                    Image("TwoUsersGray").renderingMode(.template)
                }
            }
            .tag(TabName.approvers)
            
            SettingsView(
                session: session,
                onOwnerStateUpdated: onOwnerStateUpdated
            )
            .tabItem {
                VStack {
                    Text("Settings")
                    Image("SettingsGray").renderingMode(.template)
                }
            }
            .tag(TabName.settings)
        }
        .accentColor(.black)
    }
}

#if DEBUG
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

struct VaultHomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        VaultHomeScreen(
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
