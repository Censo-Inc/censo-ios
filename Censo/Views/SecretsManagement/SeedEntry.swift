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
    var onSuccess: (API.OwnerState) -> Void

    var body: some View {
        NavigationStack {
            VStack {
                TabView(selection: $wordIndex) {
                    ForEach(0..<words.count, id: \.self) { i in
                        Word(number: i + 1, word: .init(get: {
                            words[i]
                        }, set: {
                            words[i] = $0
                        }))
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
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
            .navigationTitle(Text("Add Seed Phrase"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingDismissAlert = true
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.black)
                    }
                }
            })
            .navigationDestination(isPresented: $showingVerification) {
                SeedVerification(
                    words: words,
                    session: session,
                    publicMasterEncryptionKey: publicMasterEncryptionKey,
                    onSuccess: onSuccess
                )
            }
        }
        .sheet(isPresented: $showingAddWord, content: {
            WordEntry(number: words.count + 1) { word in
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
        if let result = BIP39.validateSeedPhrase(words: words) {
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
        SeedEntry(session: .sample, publicMasterEncryptionKey: .sample) { _ in
            
        }
    }
}

extension Base58EncodedPublicKey {
    static var sample: Self {
        try! .init(value: EncryptionKey.generateRandomKey().publicExternalRepresentation().data.base58EncodedString())
    }
}
#endif
