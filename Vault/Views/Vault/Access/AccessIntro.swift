//
//  AccessIntro.swift
//  Vault
//
//  Created by Brendan Flood on 10/25/23.
//

import SwiftUI

struct AccessIntro: View {
    @Environment(\.apiProvider) var apiProvider

    var ownerState: API.OwnerState.Ready
    var session: Session
    var onReadyToGetStarted: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading) {
                Text("Ready to start your 15 minutes of access?")
                    .font(.system(size: 24, weight: .semibold))
                    .padding()
                Text("Get ready to type your seed phrase into a secure location on another device. You will have 15 minutes to access **\(ownerState.vault.secrets[0].label)**.")
                    .font(.system(size: 18))
                    .padding()
                
                VStack(alignment: .leading) {
                    SetupStep(image: Image("PrivatePlace"), heading: "Go to a private place", content: "Make sure you are alone in your home or a highly secure area.")
                    SetupStep(
                        image: Image("FaceScan"), heading: "Scan your face", content: "When you're ready, start your 15 min access via 3D face scan.")
                    SetupStep(
                        image: Image("Timer"), heading: "Access for 15 minutes", content: "You have 15 min to access your seed phrase and cannot extend the time.")
                    Divider()
                    SetupStep(image: Image("AccessWarning"), heading: "Don't leave the app", content: "You will need to scan your face again if you leave or close the app.", opacity: 1.0)
                    Divider()
                }
                .padding()
                
                Button {
                    onReadyToGetStarted()
                } label: {
                    Text("Get started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle())
                .padding()
                
                HStack {
                    Image(systemName: "info.circle")
                    Text("Learn more")
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
    }
}

#if DEBUG
#Preview {
    NavigationView {
        AccessIntro(
            ownerState: API.OwnerState.Ready(policy: .sample, vault: .sample),
            session: .sample,
            onReadyToGetStarted: {}
        )
    }
}
#endif
