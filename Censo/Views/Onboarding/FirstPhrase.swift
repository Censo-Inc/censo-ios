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
    @State private var showingGeneratePhrase = false
    @State private var languageId: UInt8 = WordListLanguage.english.toId()

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
                
                LanguageSelection(
                    text: Text("For seed phrase input/generation, the current language is \(currentLanguage().displayName()). You may select a different language **here**"
                     ).font(.subheadline),
                    languageId: $languageId
                )
                .padding(.horizontal)
                .padding(.bottom)

                Button {
                    showingAddPhrase = true
                } label: {
                    HStack(spacing: 20) {
                        Image("PhraseEntry")
                            .resizable()
                            .frame(width: 42, height: 36)
                            .colorInvert()
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
                            .resizable()
                            .frame(width: 36, height: 36)
                        Text("Paste seed phrase")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle())
                .padding(.horizontal)
                
                Button {
                    showingGeneratePhrase = true
                } label: {
                    HStack(spacing: 20) {
                        Image(systemName: "wand.and.stars")
                            .resizable()
                            .frame(width: 36, height: 36)
                        Text("Generate phrase")
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
                language: currentLanguage(),
                onSuccess: onComplete
            )
        })
        .sheet(isPresented: $showingPastePhrase, content: {
            PastePhrase(
                onComplete: onComplete, session: session,
                ownerState: ownerState, isFirstTime: true
            )
        })
        .sheet(isPresented: $showingGeneratePhrase, content: {
            GeneratePhrase(
                language: currentLanguage(),
                onComplete: onComplete, session: session,
                ownerState: ownerState, isFirstTime: true
            )
        })
    }
    
    private func currentLanguage() ->  WordListLanguage {
        return WordListLanguage.fromId(id: languageId)
    }
}

#if DEBUG
#Preview {
    FirstPhrase(
        ownerState: API.OwnerState.Ready(policy: .sample, vault: .sample, authType: .facetec, subscriptionStatus: .active),
        session: .sample,
        onComplete: {_ in })
}
#endif
