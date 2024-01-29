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
    @State private var showingPhotoPhrase = false
    @State private var language: WordListLanguage = WordListLanguage.english

    var ownerState: API.OwnerState.Ready
    var reloadOwnerState: () -> Void
    var session: Session
    var onComplete: (API.OwnerState) -> Void
    var onCancel: () -> Void
    
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
                                    onPhotoPhrase: { showingPhotoPhrase = true }
                                )
                                .navigationTitle("")
                                .navigationBarTitleDisplayMode(.inline)
                                .toolbar(content: {
                                    ToolbarItem(placement: .navigationBarLeading) {
                                        Button {
                                            addYourOwnPhrase = false
                                        } label: {
                                            Image(systemName: "chevron.left")
                                        }
                                    }
                                })
                            } else {
                                FirstTimePhrase(
                                    onGeneratePhrase: { showingGeneratePhrase = true },
                                    onAddYourOwnPhrase: { addYourOwnPhrase = true }
                                )
                                .onboardingCancelNavBar(onCancel: onCancel)
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
                ownerState: ownerState,
                reloadOwnerState: reloadOwnerState,
                isFirstTime: true,
                language: language,
                onSuccess: onComplete,
                onBack: {
                    showingAddPhrase = false
                }
            )
        })
        .sheet(isPresented: $showingPastePhrase, content: {
            PastePhrase(
                onComplete: onComplete, 
                onBack: { showingPastePhrase = false },
                session: session, 
                ownerState: ownerState,
                reloadOwnerState: reloadOwnerState,
                isFirstTime: true
            )
        })
        .sheet(isPresented: $showingPhotoPhrase, content: {
            PhotoPhrase(
                onComplete: onComplete,
                onBack: { showingPhotoPhrase = false },
                session: session,
                ownerState: ownerState,
                reloadOwnerState: reloadOwnerState,
                isFirstTime: true
            )
        })
        .sheet(isPresented: $showingGeneratePhrase, content: {
            GeneratePhrase(
                language: WordListLanguage.english,
                onComplete: onComplete, 
                session: session,
                ownerState: ownerState, 
                reloadOwnerState: reloadOwnerState,
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
            .accessibilityIdentifier("generatePhraseButton")

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
            .accessibilityIdentifier("existingPhraseButton")
        }
        .padding(.horizontal)
        .padding([.horizontal, .bottom])
    }
}

struct AddYourOwnPhrase: View {
    var onInputPhrase: (WordListLanguage) -> Void
    var onPastePhrase: () -> Void
    var onPhotoPhrase: () -> Void
    
    @State private var languageId: UInt8 = WordListLanguage.english.toId()
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            Text("How do you want to provide your seed phrase?")
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
            
            HStack(alignment: .bottom) {
                VStack {
                    Button {
                        onInputPhrase(currentLanguage())
                    } label: {
                        Image("PhraseEntry")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(RoundedButtonStyle())
                    Text("Input")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                
                VStack {
                    Button {
                        onPhotoPhrase()
                    } label: {
                        Image(systemName: "camera")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(RoundedButtonStyle())
                    Text("Photo")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)

                VStack {
                    Button {
                        onPastePhrase()
                    } label: {
                        Image("ClipboardText")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(RoundedButtonStyle())
                    Text("Paste")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                
            }
        }
        .padding(.horizontal)
        .padding([.horizontal, .bottom])
    }
    
    private func currentLanguage() ->  WordListLanguage {
        return WordListLanguage.fromId(id: languageId)
    }
}

#if DEBUG

#Preview {
    FirstPhrase(
        ownerState: .sample,
        reloadOwnerState: {},
        session: .sample,
        onComplete: {_ in },
        onCancel: {}
    ).foregroundColor(.Censo.primaryForeground)
}
#endif
