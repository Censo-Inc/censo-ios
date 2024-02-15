//
//  Welcome.swift
//  Censo
//
//  Created by Ben Holzman on 10/10/23.
//

import SwiftUI

struct FirstPhrase: View {
    @State private var addYourOwnPhrase = false
    @State private var showingGeneratePhrase = false
    @State private var showingAddPhrase = false
    @State private var showingPastePhrase = false
    @State private var showingPhotoPhrase = false
    @State private var language: WordListLanguage = WordListLanguage.english

    var ownerState: API.OwnerState.Ready
    var onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack(alignment: .bottomTrailing) {
                    VStack(alignment: .trailing) {
                        Image("AddYourSeedPhrase")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: geometry.size.height * 0.5)
                        Spacer()
                    }
                    .padding(.top)
                    
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
                            .navigationInlineTitle("Add your first seed phrase")
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    DismissButton(icon: .back, action: {
                                        addYourOwnPhrase = false
                                    })
                                }
                            }
                        } else {
                            FirstTimePhrase(
                                onGeneratePhrase: { showingGeneratePhrase = true },
                                onAddYourOwnPhrase: { addYourOwnPhrase = true }
                            )
                            .onboardingCancelNavBar(navigationTitle: "Add your first seed phrase", onCancel: onCancel)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddPhrase, content: {
            SeedEntry(
                ownerState: ownerState,
                isFirstTime: true,
                language: language,
                onSuccess: {},
                onBack: {
                    showingAddPhrase = false
                }
            )
        })
        .sheet(isPresented: $showingPastePhrase, content: {
            PastePhrase(
                ownerState: ownerState,
                isFirstTime: true,
                onComplete: {},
                onBack: { showingPastePhrase = false }
            )
        })
        .sheet(isPresented: $showingPhotoPhrase, content: {
            PhotoPhrase(
                ownerState: ownerState,
                isFirstTime: true,
                onBack: { showingPhotoPhrase = false }
            )
        })
        .sheet(isPresented: $showingGeneratePhrase, content: {
            GeneratePhrase(
                ownerState: ownerState,
                language: WordListLanguage.english,
                isFirstTime: true,
                onComplete: {}
            )
        })
    }
}

struct FirstTimePhrase: View {
    var onGeneratePhrase: () -> Void
    var onAddYourOwnPhrase: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            Text("Time to add your first seed phrase")
                .font(.title3)
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
                        .frame(width: 24, height: 24)
                    Text("Generate new phrase")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            .padding(.vertical)
            .accessibilityIdentifier("generatePhraseButton")

            Button {
                onAddYourOwnPhrase()
            } label: {
                HStack(spacing: 10) {
                    Image("ClipboardText")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 24, height: 24)
                    Text("I have my own")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            .padding(.bottom)
            .accessibilityIdentifier("haveMyOwnButton")
        }
        .padding(.horizontal, 32)
    }
}

struct AddYourOwnPhrase: View {
    var onInputPhrase: (WordListLanguage) -> Void
    var onPastePhrase: () -> Void
    var onPhotoPhrase: () -> Void
    
    @State private var languageId: UInt8 = WordListLanguage.english.toId()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            Text("How do you want to provide your seed phrase?")
                .font(.title3)
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
                    .accessibilityIdentifier("enterPhraseButton")
                    Text("Input")
                        .font(.title3)
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
                    .accessibilityIdentifier("photoPhraseButton")
                    Text("Photo")
                        .font(.title3)
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
                    .accessibilityIdentifier("pastePhraseButton")
                    Text("Paste")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical)
        }
        .padding(.horizontal, 32)
    }
    
    private func currentLanguage() ->  WordListLanguage {
        return WordListLanguage.fromId(id: languageId)
    }
}

#if DEBUG

#Preview {
    LoggedInOwnerPreviewContainer {
        FirstPhrase(
            ownerState: .sample,
            onCancel: {}
        )
    }
}
#endif
