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
        case generatePhrase
    }
    
    @State private var step: Step = .intro
    @State private var languageId: UInt8 = WordListLanguage.english.toId()

    var ownerState: API.OwnerState.Ready
    var session: Session
    var onComplete: (API.OwnerState) -> Void
    
    var body: some View {
        switch step {
        case .intro:
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
                            Text("Add another seed phrase")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.vertical)
                            if (ownerState.vault.seedPhrases.count == 1) {
                                    Text("Storing one seed phrase with Censo is free, but to store more than one you’ll need a subscription. Go ahead and enter your seed phrase now, we’ll ask you to subscribe when you’re ready to save it.")
                                        .font(.subheadline)
                                        .padding(.bottom)
                                        .padding(.trailing)
                                }
                            LanguageSelection(
                                text: Text("For seed phrase input/generation, the current language is \(currentLanguage().displayName()). You may change it **here**"
                                          ).font(.subheadline),
                                languageId: $languageId
                            )
                            .padding(.bottom)
                            .padding(.trailing)

                            Button {
                                step = .addPhrase
                            } label: {
                                HStack(spacing: 20) {
                                    Image("PhraseEntry")
                                        .renderingMode(.template)
                                    Text("Input seed phrase")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(RoundedButtonStyle())

                            Button {
                                step = .pastePhrase
                            } label: {
                                HStack(spacing: 20) {
                                    Image("ClipboardText")
                                        .renderingMode(.template)
                                    Text("Paste seed phrase")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(RoundedButtonStyle())

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
                        }
                        .padding(.leading)
                        .padding(.horizontal)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar(content: {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button {
                                    dismiss()
                                } label: {
                                    Image(systemName: "xmark")
                                }
                            }
                        })
                    }
                }
            }
        case .addPhrase:
            SeedEntry(
                session: session,
                ownerState: ownerState,
                isFirstTime: false,
                language: currentLanguage(),
                onSuccess: { ownerState in
                    onComplete(ownerState)
                    dismiss()
                }
            )
        case .pastePhrase:
            PastePhrase(
                onComplete: { ownerState in
                    onComplete(ownerState)
                    dismiss()
                }, session: session,
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
        AdditionalPhrase(ownerState: API.OwnerState.Ready(policy: .sample, vault: .sample1Phrase, authType: .facetec, subscriptionStatus: .active, timelockSetting: .sample, subscriptionRequired: true), session: .sample, onComplete: {_ in }).foregroundColor(Color.Censo.primaryForeground)
    }
}
#endif

