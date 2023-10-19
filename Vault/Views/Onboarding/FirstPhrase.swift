//
//  Welcome.swift
//  Vault
//
//  Created by Ben Holzman on 10/10/23.
//

import SwiftUI

struct FirstPhrase: View {
    @Environment(\.apiProvider) var apiProvider
    var ownerState: API.OwnerState.Ready
    var session: Session
    var onComplete: (API.OwnerState) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
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

                NavigationLink {

                } label: {
                    HStack {
                        Image("PhraseEntry").colorInvert()
                            .padding(2)
                        Text("Enter seed phrase")
                            .font(.system(size: 24, weight: .medium))
                            .padding(2)
                    }
                }
                .buttonStyle(RoundedButtonStyle())
                .padding()
                .frame(maxWidth: .infinity)

                NavigationLink {
                    PastePhrase(onComplete: onComplete, session: session, ownerState: ownerState)
                } label: {
                    HStack {
                        Image("ClipboardText")
                            .padding(2)
                        Text("Paste seed phrase")
                            .font(.system(size: 24, weight: .medium))
                            .padding(2)
                    }
                }
                .buttonStyle(RoundedButtonStyle())
                .padding()
                .frame(maxWidth: .infinity)
                
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
    FirstPhrase(ownerState: API.OwnerState.Ready(policy: .sample, vault: .sample), session: .sample, onComplete: {_ in })
}
#endif
