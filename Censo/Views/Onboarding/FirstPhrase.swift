//
//  Welcome.swift
//  Censo
//
//  Created by Ben Holzman on 10/10/23.
//

import SwiftUI

struct FirstPhrase: View {
    @Environment(\.apiProvider) var apiProvider

    @State private var showingAddPhrase = false
    @State private var showingPastePhrase = false

    var ownerState: API.OwnerState.Ready
    var session: Session
    var onComplete: (API.OwnerState) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Spacer()
                Text("Add your first seed phrase")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding()

                Text("Your seed phrase will be encrypted so only you can access it.")
                    .font(.subheadline)
                    .padding(.horizontal)
                    .padding(.bottom)

                Button {
                    showingAddPhrase = true
                } label: {
                    HStack(spacing: 20) {
                        Image("PhraseEntry").colorInvert()
                        Text("Input seed phrase")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle())
                .padding(.horizontal)

                Button {
                    showingPastePhrase = true
                } label: {
                    HStack(spacing: 20) {
                        Image("ClipboardText")
                        Text("Paste seed phrase")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle())
                .padding(.horizontal)
              
            }
            .padding()
        }
        .sheet(isPresented: $showingAddPhrase, content: {
            SeedEntry(
                session: session,
                publicMasterEncryptionKey: ownerState.vault.publicMasterEncryptionKey,
                isFirstTime: true,
                onSuccess: onComplete
            )
        })
        .sheet(isPresented: $showingPastePhrase, content: {
            PastePhrase(
                onComplete: onComplete, session: session,
                ownerState: ownerState, isFirstTime: true
            )
        })
    }
}

#if DEBUG
#Preview {
    FirstPhrase(ownerState: API.OwnerState.Ready(policy: .sample, vault: .sample, authType: .facetec, subscriptionStatus: .active), session: .sample, onComplete: {_ in })
}
#endif
