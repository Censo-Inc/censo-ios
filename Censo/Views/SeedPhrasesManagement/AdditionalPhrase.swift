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
        case generatePhrase
        case haveMyOwn
        case addPhrase
        case pastePhrase
        case photoPhrase
    }
    
    @State private var step: Step = .intro
    @State private var languageId: UInt8 = WordListLanguage.english.toId()

    var ownerState: API.OwnerState.Ready
    var session: Session
    var onComplete: (API.OwnerState) -> Void
    
    var body: some View {
        switch step {
        case .intro, .haveMyOwn:
            NavigationStack {
                GeometryReader { geometry in
                    ZStack(alignment: .bottom) {
                        VStack {
                            Image("AddYourSeedPhrase")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(
                                    maxWidth: geometry.size.width,
                                    maxHeight: geometry.size.height * 0.6)
                            Spacer()
                        }
                        .padding(.leading)
                        .padding(.top)
                        
                        VStack(alignment: .leading) {
                            Spacer()
                            switch step {
                                
                            case .intro:
                                Text("Add another seed phrase")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .padding(.vertical)
                                
                                LanguageSelection(
                                    text: Text("You can add one of your own, or generate a new seed phrase with Censo and add that. The current language is \(currentLanguage().displayName()). You may change it **here**"
                                              ).font(.subheadline),
                                    languageId: $languageId
                                )
                                .padding(.bottom)
                                
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
                                .accessibilityIdentifier("existingPhraseButton")
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
                session: session,
                publicMasterEncryptionKey: ownerState.vault.publicMasterEncryptionKey,
                masterKeySignature: ownerState.policy.masterKeySignature,
                ownerParticipantId: ownerState.policy.owner?.participantId,
                ownerEntropy: ownerState.policy.ownerEntropy,
                isFirstTime: false,
                language: currentLanguage(),
                onSuccess: { ownerState in
                    onComplete(ownerState)
                    dismiss()
                },
                onBack: {
                    step = .haveMyOwn
                }
            )
        case .pastePhrase:
            PastePhrase(
                onComplete: { ownerState in
                    onComplete(ownerState)
                    dismiss()
                },
                onBack: {
                    step = .haveMyOwn
                },
                session: session,
                ownerState: ownerState,
                isFirstTime: false
            )
        case .photoPhrase:
            PhotoPhrase(
                onComplete: onComplete,
                onBack: {
                    step = .haveMyOwn
                },
                session: session,
                ownerState: ownerState,
                isFirstTime: false
            )
        case .generatePhrase:
            GeneratePhrase(
                language: currentLanguage(),
                onComplete: { ownerState in
                    onComplete(ownerState)
                    dismiss()
                }, session: session,
                ownerState: ownerState,
                isFirstTime: false
            )
        }
    }
    
    private func currentLanguage() ->  WordListLanguage {
        return WordListLanguage.fromId(id: languageId)
    }
}

#if DEBUG
#Preview {
    NavigationView {
        AdditionalPhrase(ownerState: API.OwnerState.Ready(policy: .sample, vault: .sample, authType: .facetec, subscriptionStatus: .active, timelockSetting: .sample), session: .sample, onComplete: {_ in }).foregroundColor(Color.Censo.primaryForeground)
    }
}
#endif

