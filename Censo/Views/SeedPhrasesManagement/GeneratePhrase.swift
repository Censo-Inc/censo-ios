//
//  GeneratePhrase.swift
//  Censo
//
//  Created by Anton Onyshchenko on 11.12.23.
//

import SwiftUI

private var wordCountOptions: [WordCount] = [
    .twelve,
    .fifteen,
    .eighteen,
    .twentyOne,
    .twentyFour
]
    
struct GeneratePhrase: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedWordCount: WordCount = .twentyFour
    @State private var showingError = false
    @State private var error: Error?
    @State private var showingVerification = false
    @State private var phrase: [String] = []
    
    var language: WordListLanguage
    var onComplete: (API.OwnerState) -> Void
    var session: Session
    var ownerState: API.OwnerState.Ready
    var isFirstTime: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                Text("How long should the seed phrase be?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding()
                
                VStack(spacing: 20) {
                    ForEach(wordCountOptions, id: \.self) { wordCount in
                        Button {
                            self.selectedWordCount = wordCount
                        } label: {
                            WordCountOption(
                                wordCount: wordCount,
                                isSelected: selectedWordCount == wordCount
                            )
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
                
                Button {
                    generatePhrase()
                } label: {
                    Text("Generate")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(5)
                }
                .buttonStyle(RoundedButtonStyle())
                .padding(.horizontal)
                .padding(.bottom)
                .accessibilityIdentifier("generateButton")
            }
            .multilineTextAlignment(.center)
            .navigationTitle(Text("Add Seed Phrase"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
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
            .alert("Error", isPresented: $showingError, presenting: error) { _ in
                Button {
                    self.error = nil
                    self.showingError = false
                } label: { Text("OK") }
            } message: { error in
                Text(error.localizedDescription)
            }
            .navigationDestination(isPresented: $showingVerification, destination: {
                SeedVerification(
                    words: phrase,
                    session: session,
                    publicMasterEncryptionKey: ownerState.vault.publicMasterEncryptionKey,
                    masterKeySignature: ownerState.policy.masterKeySignature,
                    ownerParticipantId: ownerState.policy.owner?.participantId,
                    ownerEntropy: ownerState.policy.ownerEntropy,
                    isFirstTime: isFirstTime
                ) { ownerState in
                    onComplete(ownerState)
                    dismiss()
                }
            })
        }
    }
    
    func generatePhrase() {
        do {
            self.phrase = try BIP39.generatePhrase(wordCount: selectedWordCount, language: language)
            if let result = BIP39.validateSeedPhrase(words: phrase, language: language) {
                self.showingError = true
                self.error = PhraseValidityError.invalid(result)
            } else {
                self.showingVerification = true
            }
        } catch {
            self.showingError = true
            self.error = error
        }
    }
}

struct WordCountOption: View {
    var wordCount: WordCount
    var isSelected: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark")
                    .resizable()
                    .symbolRenderingMode(.palette)
                    .foregroundColor(.black)
                    .frame(width: 12, height: 12)
                    .padding([.trailing], 12)
            } else {
                Text("")
                    .padding(.trailing, 24)
            }
            
            Text("\(wordCount.rawValue) words")
                .font(.subheadline)
                .foregroundColor(.black)
                .bold()
                .padding(.trailing, 24)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 16.0)
                .stroke(isSelected == true ? Color.black : Color.gray, lineWidth: 1)
        )
    }
}

#if DEBUG
#Preview {
    GeneratePhrase(
        language: WordListLanguage.english,
        onComplete: {_ in },
        session: .sample,
        ownerState: API.OwnerState.Ready(policy: .sample, vault: .sample, authType: .facetec, subscriptionStatus: .active, timelockSetting: .sample),
        isFirstTime: false
    )
}
#endif
