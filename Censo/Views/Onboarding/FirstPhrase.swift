//
//  Welcome.swift
//  Censo
//
//  Created by Ben Holzman on 10/10/23.
//

import SwiftUI

struct FirstPhrase: View {
    @Environment(\.apiProvider) var apiProvider

    @State private var addYourOwnPhrase = false
    @State private var showingGeneratePhrase = false
    @State private var showingAddPhrase = false
    @State private var showingPastePhrase = false
    @State private var language: WordListLanguage = WordListLanguage.english

    var ownerState: API.OwnerState.Ready
    var session: Session
    var onComplete: (API.OwnerState) -> Void
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                    
                        VStack {
                            Spacer()
                            if addYourOwnPhrase {
                                AddYourOwnPhrase(
                                    onInputPhrase: { selectedLanguage in
                                        language = selectedLanguage
                                        showingAddPhrase = true
                                    },
                                    onPastePhrase: { showingPastePhrase = true },
                                    onBack: { addYourOwnPhrase = false }
                                )
                            } else {
                                FirstTimePhrase(
                                    onGeneratePhrase: { showingGeneratePhrase = true },
                                    onAddYourOwnPhrase: { addYourOwnPhrase = true }
                                )
                            }
                        }
                        .background {
                            VStack {
                                Spacer()
                                    .frame(maxHeight: geometry.size.height * 0.05)
                                Image("AddYourSeedPhrase")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: geometry.size.width * 0.8)
                                Spacer()
                            }
                        }
            }
        }
        .sheet(isPresented: $showingAddPhrase, content: {
            SeedEntry(
                session: session,
                publicMasterEncryptionKey: ownerState.vault.publicMasterEncryptionKey,
                masterKeySignature: ownerState.policy.masterKeySignature,
                ownerParticipantId: ownerState.policy.owner?.participantId,
                isFirstTime: true,
                language: language,
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
                language: WordListLanguage.english,
                onComplete: onComplete, 
                session: session,
                ownerState: ownerState, 
                isFirstTime: true
            )
        })
    }
}

struct FirstTimePhrase: View {
    var onGeneratePhrase: () -> Void
    var onAddYourOwnPhrase: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Spacer()
            Text("Time to add your first seed phrase")
                .font(.title2)
                .fontWeight(.semibold)
                .fixedSize(horizontal: false, vertical: true)
            
            Text("You can add one of your own, or if you would like to try Censo first, generate a new seed phrase with Censo and add that.")
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical)
            Button {
                onGeneratePhrase()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "wand.and.stars")
                        .resizable()
                        .frame(width: 36, height: 36)
                    Text("Generate new phrase")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            
            Button {
                onAddYourOwnPhrase()
            } label: {
                HStack(spacing: 10) {
                    Image("ClipboardText").renderingMode(.template)
                    Text("I have my own")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())

        }
        .padding(.horizontal)
        .padding(.horizontal)
    }
}

struct AddYourOwnPhrase: View {
    var onInputPhrase: (WordListLanguage) -> Void
    var onPastePhrase: () -> Void
    var onBack: () -> Void
    
    @State private var languageId: UInt8 = WordListLanguage.english.toId()
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            Text("Time to add your first seed phrase")
                .font(.title2)
                .fontWeight(.semibold)
                .fixedSize(horizontal: false, vertical: true)
            
            LanguageSelection(
                text: Text(
                    "For seed phrase input, the current language is \(currentLanguage().displayName()). You may select a different language **here**"
                )
                .font(.subheadline),
                languageId: $languageId
            )
            .padding(.vertical)
            
            Button {
                onInputPhrase(currentLanguage())
            } label: {
                HStack(spacing: 20) {
                    Image("PhraseEntry").renderingMode(.template)
                    Text("Input seed phrase")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            
            Button {
                onPastePhrase()
            } label: {
                HStack(spacing: 20) {
                    Image("ClipboardText").renderingMode(.template)
                    Text("Paste seed phrase")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            
            Button {
                onBack()
            } label: {
                HStack(spacing: 20) {
                    Image(systemName: "arrowshape.backward.fill").renderingMode(.template)
                    Text("Back")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
        }
        .padding(.horizontal)
        .padding(.horizontal)
    }
    
    private func currentLanguage() ->  WordListLanguage {
        return WordListLanguage.fromId(id: languageId)
    }
}

#if DEBUG
#Preview {
    FirstPhrase(
        ownerState: API.OwnerState.Ready(policy: .sample, vault: .sample, authType: .facetec, subscriptionStatus: .active, timelockSetting: .sample),
        session: .sample,
        onComplete: {_ in }
    ).foregroundColor(.Censo.primaryForeground)
}
#endif
