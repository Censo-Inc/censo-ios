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
    
    var ownerState: API.OwnerState.Ready
    var language: WordListLanguage
    var isFirstTime: Bool
    var onComplete: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                Text("How long should the seed phrase be?")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.vertical)
                
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
                        }
                    }
                }
                .padding(.bottom)
                
                Button {
                    generatePhrase()
                } label: {
                    Text("Generate")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle())
                .padding(.bottom)
                .accessibilityIdentifier("generateButton")
            }
            .padding(.horizontal, 32)
            .multilineTextAlignment(.center)
            .navigationInlineTitle("Generate seed phrase")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    DismissButton(icon: .close)
                }
            }
            .errorAlert(isPresented: $showingError, presenting: error)
            .navigationDestination(isPresented: $showingVerification, destination: {
                SeedVerification(
                    words: phrase,
                    ownerState: ownerState,
                    isFirstTime: isFirstTime,
                    onSuccess: {
                        onComplete()
                        dismiss()
                    }
                )
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
    LoggedInOwnerPreviewContainer {
        GeneratePhrase(
            ownerState: .sample,
            language: WordListLanguage.english,
            isFirstTime: false,
            onComplete: {}
        )
    }
}
#endif
