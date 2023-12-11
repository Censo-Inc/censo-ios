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
                VStack(alignment: .leading, spacing: 20) {
                    Spacer()
                    Text("Add another seed phrase")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding()
                    
                    Text("Your seed phrase will be encrypted so only you can access it.")
                        .font(.subheadline)
                        .padding(.horizontal)
                        .padding(.bottom)
                    
                    LanguageSelection(
                        text: Text("For seed phrase input/generation, the current language is \(currentLanguage().displayName()). You may change it **here**"
                         ).font(.subheadline),
                        languageId: $languageId
                    )
                    .padding(.horizontal)
                    .padding(.bottom)
                    
                    Button {
                        step = .addPhrase
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
                        step = .pastePhrase
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
                    .padding(.horizontal)
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
        AdditionalPhrase(ownerState: API.OwnerState.Ready(policy: .sample, vault: .sample, authType: .facetec, subscriptionStatus: .active), session: .sample, onComplete: {_ in })
    }
}
#endif

