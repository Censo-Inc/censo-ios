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
    var masterKeySignature: Base64EncodedString?
    var ownerParticipantId: ParticipantId?
    var ownerEntropy: Base64EncodedString?
    var isFirstTime: Bool
    var requestedLabel: String? = nil
    var onClose: (() -> Void)? = nil
    var onSuccess: (API.OwnerState) -> Void

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
            
                Spacer()
                
                WordList(words: words)
                    .padding(.horizontal)
                    .frame(height: geometry.size.height * 0.4)
                
                Button {
                    showingSave = true
                } label: {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle())
                .padding()
            }
        }
        .background(
            GeometryReader { geometry in
                VStack {
                    Image("SeedPhraseValidated")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
        )
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
                masterKeySignature: masterKeySignature,
                ownerParticipantId: ownerParticipantId,
                ownerEntropy: ownerEntropy,
                isFirstTime: isFirstTime,
                requestedLabel: requestedLabel,
                onSuccess: onSuccess
            )
        }
    }
}

#if DEBUG
struct SeedVerification_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SeedVerification(words: ["sample", "word"], session: .sample, publicMasterEncryptionKey: .sample, ownerEntropy: .sample, isFirstTime: true) { _ in }.foregroundColor(.Censo.primaryForeground)
        }
        NavigationStack {
            SeedVerification(words: ["donor", "tower", "topic", "path", "obey", "intact", "lyrics", "list", "hair", "slice", "cluster", "grunt"], session: .sample, publicMasterEncryptionKey: .sample, ownerEntropy: .sample, isFirstTime: true) { _ in }
        }
    }
}
#endif
