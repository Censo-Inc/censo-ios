//
//  AccessIntro.swift
//  Censo
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
            VStack(alignment: .leading, spacing: 0) {
                Text("Ready to start your 15 minutes of access?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding()

                VStack(alignment: .leading) {
                    SetupStep(image: Image("PrivatePlace"), heading: "Go to a private place", content: "Make sure you are alone in your home or a secure area.")
                    if ownerState.authType == .password {
                        SetupStep(
                            image: Image("PhraseEntry"), heading: "Enter your password", content: "Start your access by entering your password. If you leave the app you will need to enter your password again.")
                    } else {
                        SetupStep(
                            image: Image("FaceScan"), heading: "Scan your face", content: "Start your access with a face scan. If you leave the app you will need to scan your face again.")
                    }
                    SetupStep(
                        image: Image("Timer"), heading: "Access for 15 minutes", content: "You have 15 minutes to access your seed phrase. If you need more time, you will have to scan your face again.")
                }
                .padding(.horizontal)
                .padding(.vertical, 20)
                
                Button {
                    onReadyToGetStarted()
                } label: {
                    Text("Get started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle())
                .padding()
                
            }
            .padding()
        }
    }
}

#if DEBUG
#Preview {
    NavigationView {
        AccessIntro(
            ownerState: API.OwnerState.Ready(policy: .sample, vault: .sample, authType: .facetec, subscriptionStatus: .active),
            session: .sample,
            onReadyToGetStarted: {}
        )
    }
}
#endif
