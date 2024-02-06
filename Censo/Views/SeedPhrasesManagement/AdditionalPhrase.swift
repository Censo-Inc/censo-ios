//
//  AdditionalPhrase.swift
//  Censo
//
//  Created by Brendan Flood on 10/10/23.
//

import SwiftUI

struct AdditionalPhrase: View {
    @Environment(\.dismiss) var dismiss
    
    enum Step {
        case intro
        case generatePhrase
        case haveMyOwn
        case addPhrase
        case pastePhrase
        case photoPhrase
    }
    
    @State private var step: Step = .intro
    @State private var languageId: UInt8 = WordListLanguage.english.toId()

    var ownerState: API.OwnerState.Ready
    
    var body: some View {
        switch step {
        case .intro, .haveMyOwn:
            NavigationStack {
                GeometryReader { geometry in
                    ZStack(alignment: .bottomTrailing) {
                        VStack(alignment: .trailing) {
                            Image("AddYourSeedPhrase")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(
                                    maxHeight: geometry.size.height * 0.5)
                            Spacer()
                        }
                        .padding(.top)

                        VStack(alignment: .leading) {
                            Spacer()
                            switch step {
                                
                            case .intro:
                                if (ownerState.vault.seedPhrases.count == 1) {
                                    Text("Storing one seed phrase with Censo is free, but to store more than one you’ll need a subscription. Go ahead and enter your seed phrase now, we’ll ask you to subscribe when you’re ready to save it.")
                                        .font(.subheadline)
                                        .padding(.bottom)
                                        .padding(.trailing)
                                }
                                LanguageSelection(
                                    text: Text("You can add one of your own, or generate a new seed phrase with Censo and add that. The current language is \(currentLanguage().displayName()). You may change it **here**"
                                              ).font(.subheadline),
                                    languageId: $languageId
                                )
                                .padding(.bottom)
                                .padding(.trailing)

                                Button {
                                    step = .generatePhrase
                                } label: {
                                    HStack(spacing: 20) {
                                        Image(systemName: "wand.and.stars")
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                        Text("Generate phrase")
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(RoundedButtonStyle())
                                .padding(.bottom, 5)
                                .accessibilityIdentifier("generatePhraseButton")
                                
                                Button {
                                    step = .haveMyOwn
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
                                .accessibilityIdentifier("haveMyOwnButton")
                            case .haveMyOwn:
                                Text("How do you want to provide your seed phrase?")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .padding(.vertical)
                                
                                LanguageSelection(
                                    text: Text("The current language for Paste or Input is \(currentLanguage().displayName()). You may change it **here**"
                                              ).font(.subheadline),
                                    languageId: $languageId
                                )
                                .padding(.bottom)
                                
                                HStack(alignment: .bottom) {
                                    VStack {
                                        Button {
                                            step = .addPhrase
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
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)

                                    VStack {
                                        Button {
                                            step = .photoPhrase
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
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    
                                    VStack {
                                        Button {
                                            step = .pastePhrase
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
                                            .font(.title2)
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    
                                }
                            case .addPhrase, .generatePhrase, .pastePhrase, .photoPhrase:
                                EmptyView()
                            }
                        }
                        .padding(.leading)
                        .padding(.horizontal)
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationTitle("Add another seed phrase")
                        .toolbar(content: {
                            switch step {
                            case .intro:
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button {
                                        dismiss()
                                    } label: {
                                        Image(systemName: "xmark")
                                    }
                                }
                            case .haveMyOwn:
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button {
                                        step = .intro
                                    } label: {
                                        Image(systemName: "chevron.left")
                                    }
                                }
                            case .addPhrase, .generatePhrase, .pastePhrase, .photoPhrase:
                                ToolbarItem() {
                                    EmptyView()
                                }
                            }
                        })
                    }
                }
            }
        case .addPhrase:
            SeedEntry(
                ownerState: ownerState,
                isFirstTime: false,
                language: currentLanguage(),
                onSuccess: {
                    dismiss()
                },
                onBack: {
                    step = .haveMyOwn
                }
            )
        case .pastePhrase:
            PastePhrase(
                ownerState: ownerState,
                isFirstTime: false,
                onComplete: {
                    dismiss()
                },
                onBack: {
                    step = .haveMyOwn
                }
            )
        case .photoPhrase:
            PhotoPhrase(
                ownerState: ownerState,
                isFirstTime: false,
                onBack: {
                    step = .haveMyOwn
                }
            )
        case .generatePhrase:
            GeneratePhrase(
                ownerState: ownerState,
                language: currentLanguage(),
                isFirstTime: false,
                onComplete: {
                    dismiss()
                }
            )
        }
    }
    
    private func currentLanguage() ->  WordListLanguage {
        return WordListLanguage.fromId(id: languageId)
    }
}

#if DEBUG
#Preview {
    LoggedInOwnerPreviewContainer {
        NavigationView {
            AdditionalPhrase(
                ownerState: API.OwnerState.Ready(
                    policy: .sample,
                    vault: .sample1Phrase,
                    authType: .facetec,
                    subscriptionStatus: .active,
                    timelockSetting: .sample,
                    subscriptionRequired: true,
                    onboarded: true,
                    canRequestAuthenticationReset: false
                )
            )
        }
    }
}
#endif

