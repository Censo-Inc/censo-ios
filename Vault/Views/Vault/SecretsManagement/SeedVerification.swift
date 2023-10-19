//
//  SeedVerification.swift
//  Vault
//
//  Created by Ata Namvari on 2023-10-19.
//

import SwiftUI

struct SeedVerification: View {
    @Environment(\.dismiss) var dismiss

    @State private var showingSave = false
    @State private var showingDismissAlert = false

    var words: [String]
    var session: Session
    var publicMasterEncryptionKey: Base58EncodedPublicKey
    var onSuccess: (API.OwnerState) -> Void

    var body: some View {
        VStack {
            Image(systemName: "checkmark.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding()
                .padding(.horizontal, 100)

            Text("Seed phrase verified")
                .font(.title)

            Text("Censo has verified that this is a valid seed phrase. Please review the words to make sure that you have entered them correctly.")
                .padding()

            TabView {
                ForEach(0..<words.count, id: \.self) { i in
                    VStack {
                        Group {
                            Text(NumberFormatter.ordinal.string(from: NSNumber(value: i + 1)) ?? "") + Text(" word")
                        }
                        .font(.title2)
                        .padding()

                        Text(words[i])
                            .padding()
                            .multilineTextAlignment(.center)
                            .font(.title)
                            .padding()
                    }
                    .frame(maxWidth: .infinity)
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(lineWidth: 1)
                    }
                    .padding(20)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))

            Button {
                showingSave = true
            } label: {
                Text("Next")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            .padding()
        }
        .multilineTextAlignment(.center)
        .navigationTitle(Text("Add Seed Phrase"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                BackButton()
            }
        })
        .alert("Are you sure?", isPresented: $showingDismissAlert) {
            Button(role: .destructive, action: { dismiss() }) {
                Text("Exit")
            }
        } message: {
            Text("Your progress will be lost")
        }
        .interactiveDismissDisabled()
        .navigationDestination(isPresented: $showingSave) {
            SaveSeedPhrase(
                words: words,
                session: session,
                publicMasterEncryptionKey: publicMasterEncryptionKey,
                onSuccess: onSuccess
            )
        }
    }
}

#if DEBUG
struct SeedVerification_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SeedVerification(words: ["sample", "word"], session: .sample, publicMasterEncryptionKey: .sample) { _ in
            }
        }
    }
}
#endif
