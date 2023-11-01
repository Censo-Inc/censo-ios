//
//  AdditionalPhrase.swift
//  Censo
//
//  Created by Brendan Flood on 10/10/23.
//

import SwiftUI

struct AdditionalPhrase: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss
    
    enum Step {
        case intro
        case addPhrase
        case pastePhrase
    }
    
    @State private var step: Step = .intro

    var ownerState: API.OwnerState.Ready
    var session: Session
    var onComplete: (API.OwnerState) -> Void
    
    var body: some View {
        switch step {
        case .intro:
            NavigationStack {
                VStack(alignment: .leading, spacing: 20) {
                    Spacer()
                    Text("Add another seed phrase")
                        .font(.system(size: 24, weight: .semibold))
                        .padding()
                    Text("Add a seed phrase to store it safely with Censo. Your seed phrase is sharded and encrypted for ultimate security.")
                        .font(.system(size: 14))
                        .padding(.horizontal)
                    Text("Only you can retrieve your seed phrase. Neither Censo nor trusted approvers can access it.")
                        .font(.system(size: 14))
                        .padding()
                    
                    Button {
                        step = .addPhrase
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
                        step = .pastePhrase
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
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.black)
                        }
                    }
                })
                .padding()
            }
            
        case .addPhrase:
            SeedEntry(
                session: session,
                publicMasterEncryptionKey: ownerState.vault.publicMasterEncryptionKey,
                onSuccess: onComplete
            )
        case .pastePhrase:
            PastePhrase(
                onComplete: onComplete,
                session: session,
                ownerState: ownerState
            )
        }
    }
}

#if DEBUG
#Preview {
    NavigationView {
        AdditionalPhrase(ownerState: API.OwnerState.Ready(policy: .sample, vault: .sample), session: .sample, onComplete: {_ in })
    }
}
#endif
