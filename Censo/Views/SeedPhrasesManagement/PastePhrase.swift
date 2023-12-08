//
//  PastePhrase.swift
//  Censo
//
//  Created by Ben Holzman on 10/16/23.
//

import SwiftUI
import CryptoKit
import Moya

enum PhraseValidityError: Error, LocalizedError {
    case invalid(BIP39InvalidReason)
    case empty

    var errorDescription: String? {
        switch self {
        case .invalid(let reason):
            return reason.description
        case .empty:
            return "Couldn't find anything in the clipboard"
        }
    }
}

struct PastePhrase: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss
    
    @State private var showingError = false
    @State private var error: Error?
    @State private var pastedPhrase: String = ""
    @State private var showingVerification = false
    
    var onComplete: (API.OwnerState) -> Void
    var session: Session
    var ownerState: API.OwnerState.Ready
    var isFirstTime: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack(spacing: 0) {
                    Text("Paste seed phrase")
                        .font(.title)
                        .bold()
                    
                    Spacer()
                        .frame(maxHeight: 50)

                    HStack(alignment: .top, spacing: 20) {
                        Image(systemName: "doc.on.clipboard")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .padding(12)
                            .background(.gray.opacity(0.25))
                            .clipShape(RoundedRectangle(cornerRadius: 16.0))
                            
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("1. Copy your seed phrase")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .padding(.bottom)
                            
                            Text("Open the app where your seed phrase is, copy it to the clipboard, and then come back here.")
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom)
                    
                    HStack(alignment: .top) {
                        
                        Image(systemName: "square.and.arrow.down")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .padding(12)
                            .background(.gray.opacity(0.25))
                            .clipShape(RoundedRectangle(cornerRadius: 16.0))
                            .padding(.trailing)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("2. Tap the button below")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .padding(.bottom)
                            
                            Text("When you tap the Paste From Clipboard button, your seed phrase will be pasted from the clipboard, and the clipboard will then be cleared.\n\nYou will then have the opportunity to review the seed phrase before saving it.")
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    Spacer()
                    Button {
                        validatePhrase()
                    } label: {
                        Text("Paste From Clipboard")
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(RoundedButtonStyle())
                    
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.black)
                    }
                }
            }
            .alert("Error", isPresented: $showingError, presenting: error) { _ in
                Button { } label: { Text("OK") }
            } message: { error in
                Text(error.localizedDescription)
            }
            .navigationDestination(isPresented: $showingVerification, destination: {
                SeedVerification(
                    words: BIP39.splitToWords(phrase: pastedPhrase),
                    session: session,
                    publicMasterEncryptionKey: ownerState.vault.publicMasterEncryptionKey,
                    isFirstTime: isFirstTime
                ) { ownerState in
                    onComplete(ownerState)
                    dismiss()
                }
            })
        }
    }

    private func validatePhrase() {
        guard let phrase = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
            showingError = true
            error = PhraseValidityError.empty
            return
        }
        UIPasteboard.general.string = ""

        if let result = BIP39.validateSeedPhrase(phrase: phrase) {
            showingError = true
            error = PhraseValidityError.invalid(result)
        } else {
            pastedPhrase = phrase
            showingVerification = true
        }
    }
}

#if DEBUG
#Preview {
    PastePhrase(
        onComplete: {_ in},
        session: .sample,
        ownerState: API.OwnerState.Ready(policy: .sample, vault: .sample, authType: .facetec, subscriptionStatus: .active),
        isFirstTime: true
    )
}
#endif
