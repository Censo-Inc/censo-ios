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
                                .frame(maxHeight: geometry.size.height * 0.5)
                            Spacer()
                        }
                        .padding(.top)

                        VStack(alignment: .leading, spacing: 0) {
                            Spacer()
                            switch step {
                                
                            case .intro:
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
                                    HStack(spacing: 10) {
                                        Image(systemName: "wand.and.stars")
                                            .resizable()
                                            .frame(width: 24, height: 24)
                                        Text("Generate phrase")
                                            .font(.headline)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(RoundedButtonStyle())
                                .padding(.vertical)
                                .accessibilityIdentifier("generatePhraseButton")
                                
                                Button {
                                    step = .haveMyOwn
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
                            case .haveMyOwn:
                                Text("How do you want to provide your seed phrase?")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                LanguageSelection(
                                    text: Text("The current language for Paste or Input is \(currentLanguage().displayName()). You may change it **here**").font(.subheadline),
                                    languageId: $languageId
                                )
                                .padding(.vertical)
                                
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
                                            .font(.title3)
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
                                            .font(.title3)
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
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .padding(.vertical)
                            case .addPhrase, .generatePhrase, .pastePhrase, .photoPhrase:
                                EmptyView()
                            }
                        }
                        .padding(.horizontal, 32)
                        .navigationInlineTitle("Add another seed phrase")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                switch step {
                                case .intro:
                                    DismissButton(icon: .close)
                                case .haveMyOwn:
                                    DismissButton(icon: .back, action: {
                                        step = .intro
                                    })
                                case .addPhrase, .generatePhrase, .pastePhrase, .photoPhrase:
                                    EmptyView()
                                }
                            }
                        }
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
        Text("")
            .sheet(isPresented: Binding.constant(true), content: {
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
            })
    }
}
#endif

