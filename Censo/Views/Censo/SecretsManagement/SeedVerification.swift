//
//  SeedVerification.swift
//  Censo
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

            Text("Seed phrase validated")
                .font(.title)

            Text("Censo has verified that this is a valid seed phrase. Please review the words to make sure that you have entered them correctly.")
                .padding()

            WordList(words: words)

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
        .navigationBarBackButtonHidden(true)
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
