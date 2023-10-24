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
    var policy: API.Policy
    var vault: API.Vault
    var recovery: API.Recovery?
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    
    var body: some View {
        TabView {
            HomeView(
                session: session,
                policy: policy,
                vault: vault,
                onOwnerStateUpdated: onOwnerStateUpdated
            )
            .tabItem {
                VStack {
                    Text("Home")
                    Image("SimpleHomeGray").renderingMode(.template)
                }
            }
            
            PhrasesView(
                session: session,
                policy: policy,
                vault: vault,
                recovery: recovery,
                onOwnerStateUpdated: onOwnerStateUpdated
            )
            .tabItem {
                VStack {
                    Text("Phrases")
                    Image("LockSimpleGray").renderingMode(.template)
                }
            }
            
            ApproversView(
            )
            .tabItem {
                VStack {
                    Text("Approvers")
                    Image("TwoUsersGray").renderingMode(.template)
                }
            }
            
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
            secrets: [.sample],
            publicMasterEncryptionKey: try! Base58EncodedPublicKey(value: "PQVchxggKG9sQRNx9Yi6Yu5gSCeLQFmxuCzmx1zmNBdRVoCTPeab1F612GE4N7UZezqGBDYUB25yGuFzWsob9wY2")
        )
    }
}

extension API.VaultSecret {
    static var sample: Self {
        .init(guid: "", encryptedSeedPhrase: .sample, seedPhraseHash: .sample, label: "Test", createdAt: Date())
    }
}

struct VaultHomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        VaultHomeScreen(
            session: .sample,
            policy: .sample,
            vault: .sample,
            recovery: nil,
            onOwnerStateUpdated: { _ in }
        )
    }
}
#endif
