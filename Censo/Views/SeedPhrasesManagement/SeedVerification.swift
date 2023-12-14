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
    var isFirstTime: Bool
    var onClose: (() -> Void)? = nil
    var isGeneratedPhrase: Bool = false
    var onSuccess: (API.OwnerState) -> Void

    var body: some View {
        VStack {
            Spacer()

            Image(systemName: "checkmark.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(minWidth: 64, minHeight: 64)
                .frame(maxWidth: 128, maxHeight: 128)
                .padding(.top)

            Spacer()

            if isGeneratedPhrase {
                Text("Seed phrase generated")
                    .font(.title)
            } else {
                Text("Seed phrase validated")
                    .font(.title)

                Text("Censo has verified that this is a valid seed phrase. Please review the words to make sure that you have entered them correctly.")
                    .fixedSize(horizontal: false, vertical: true)
                    .padding()
            }

            WordList(words: words)
                .padding(.horizontal)
                .frame(height: 250)

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
                if (onClose == nil) {
                    BackButton()
                } else {
                    Button {
                        onClose!()
                    } label: {
                        Image(systemName: "xmark")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 18, height: 18)
                            .foregroundColor(.black)
                            .font(.body.bold())
                    }
                }
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
                isFirstTime: isFirstTime,
                onSuccess: onSuccess
            )
        }
    }
}

#if DEBUG
struct SeedVerification_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SeedVerification(words: ["sample", "word"], session: .sample, publicMasterEncryptionKey: .sample, isFirstTime: true) { _ in }
        }
        NavigationStack {
            SeedVerification(words: ["donor", "tower", "topic", "path", "obey", "intact", "lyrics", "list", "hair", "slice", "cluster", "grunt"], session: .sample, publicMasterEncryptionKey: .sample, isFirstTime: true, isGeneratedPhrase: true) { _ in }
        }
    }
}
#endif
