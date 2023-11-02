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
                    .font(.system(size: 24, weight: .semibold))
                    .padding()
                Text("Your seed phrase will be encrypted so only you can access it.")
                    .font(.system(size: 14))
                    .padding(.horizontal)

                Button {
                    showingAddPhrase = true
                } label: {
                    HStack(spacing: 20) {
                        Image("PhraseEntry").colorInvert()
                        Text("Input seed phrase")
                            .font(.title2)
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
                onSuccess: onComplete
            )
        })
        .sheet(isPresented: $showingPastePhrase, content: {
            PastePhrase(
                session: session,
                ownerState: ownerState,
                onComplete: onComplete
            )
        })
    }
}

#if DEBUG
#Preview {
    FirstPhrase(ownerState: API.OwnerState.Ready(policy: .sample, vault: .sample), session: .sample, onComplete: {_ in })
}
#endif
