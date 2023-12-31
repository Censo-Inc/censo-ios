//
//  SeedEntry.swift
//  Censo
//
//  Created by Ata Namvari on 2023-10-19.
//

import SwiftUI

struct SeedEntry: View {
    @Environment(\.dismiss) var dismiss

    @State private var wordIndex = 0
    @State private var words: [String] = []
    @State private var showingAddWord = false
    @State private var invalidReason: BIP39InvalidReason?
    @State private var showingError = false
    @State private var showingVerification = false
    @State private var showingDismissAlert = false

    var session: Session
    var publicMasterEncryptionKey: Base58EncodedPublicKey
    var masterKeySignature: Base64EncodedString?
    var ownerParticipantId: ParticipantId?
    var isFirstTime: Bool
    var language: WordListLanguage
    var onSuccess: (API.OwnerState) -> Void

    var body: some View {
        NavigationStack {
            VStack {
                TabView(selection: $wordIndex) {
                    ForEach(0..<words.count, id: \.self) { i in
                        Word(number: i + 1, language: language, word: .init(get: {
                            words[i]
                        }, set: {
                            words[i] = $0
                        }), deleteWord: {
                            words.remove(at: i)
                            wordIndex = max(0, min(i, words.count - 1))
                        })
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))

                Text("\(words.count) word\(words.count == 1 ? "" : "s") total")

                Divider()

                HStack {
                    Button {
                        showingAddWord = true
                    } label: {
                        Text("Enter \(words.isEmpty ? "first" : "next") word")
                            .padding(5)
                    }
                    .padding(5)
                    .disabled(words.last?.isEmpty ?? false)

                    Button {
                        finish()
                    } label: {
                        Text("Finish")
                            .padding(5)
                    }
                    .padding(5)
                    .disabled(words.isEmpty)
                }
                .buttonStyle(RoundedButtonStyle())
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Text("Add Seed Phrase"))
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingDismissAlert = true
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            })
            .navigationDestination(isPresented: $showingVerification) {
                SeedVerification(
                    words: words,
                    session: session,
                    publicMasterEncryptionKey: publicMasterEncryptionKey,
                    masterKeySignature: masterKeySignature,
                    ownerParticipantId: ownerParticipantId,
                    isFirstTime: isFirstTime,
                    onSuccess: onSuccess
                )
            }
        }
        .sheet(isPresented: $showingAddWord, content: {
            WordEntry(number: words.count + 1, language: language) { word in
                showingAddWord = false
                words.append(word)
                wordIndex = words.count - 1
                
            }
        })
        .alert("Error", isPresented: $showingError, presenting: invalidReason) { _ in
            Button { } label: { Text("OK") }
        } message: { reason in
            Text(reason.description)
        }
        .alert("Are you sure?", isPresented: $showingDismissAlert) {
            Button(role: .destructive, action: { dismiss() }) {
                Text("Exit")
            }
        } message: {
            Text("Your progress will be lost")
        }
        .interactiveDismissDisabled()
    }

    private func finish() {
        if let result = BIP39.validateSeedPhrase(words: words, language: language) {
            showingError = true
            invalidReason = result
        } else {
            showingVerification = true
        }
    }
}

#if DEBUG
struct SeedEntry_Previews: PreviewProvider {
    static var previews: some View {
        SeedEntry(
            session: .sample,
            publicMasterEncryptionKey: .sample,
            isFirstTime: true,
            language: WordListLanguage.english) { _ in
            
        }.foregroundColor(Color.Censo.primaryForeground)
    }
}

extension Base58EncodedPublicKey {
    static var sample: Self {
        try! .init(value: EncryptionKey.generateRandomKey().publicExternalRepresentation().data.base58EncodedString())
    }
}
#endif
