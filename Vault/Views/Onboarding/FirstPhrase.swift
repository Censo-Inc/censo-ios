//
//  Welcome.swift
//  Vault
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
                Text("Step 2")
                    .font(.system(size: 18, weight: .semibold))
                    .padding()
                Text("Add your first seed phrase")
                    .font(.system(size: 24, weight: .semibold))
                    .padding()
                Text("Add a seed phrase to store it safely with Censo. Your seed phrase is sharded and encrypted for ultimate security.")
                    .font(.system(size: 14))
                    .padding(.horizontal)
                Text("Only you can retrieve your seed phrase. Neither Censo nor trusted approvers can access it.")
                    .font(.system(size: 14))
                    .padding()

                Button {
                    showingAddPhrase = true
                } label: {
                    HStack(spacing: 20) {
                        Image("PhraseEntry").colorInvert()
                        Text("Enter seed phrase")
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
                
                HStack {
                    Image(systemName: "info.circle")
                    Text("Learn more")
                }
                .frame(maxWidth: .infinity)
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
                onComplete: onComplete,
                session: session,
                ownerState: ownerState
            )
        })
    }
}

#if DEBUG
#Preview {
    FirstPhrase(ownerState: API.OwnerState.Ready(policy: .sample, vault: .sample), session: .sample, onComplete: {_ in })
}
#endif
