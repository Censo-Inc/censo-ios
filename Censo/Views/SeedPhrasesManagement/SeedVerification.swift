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
    var ownerState: API.OwnerState.Ready
    var isFirstTime: Bool
    var requestedLabel: String? = nil
    var onClose: (() -> Void)? = nil
    var onSuccess: () -> Void

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                
                WordList(words: words)
                    .frame(height: geometry.size.height * 0.4)
                
                Button {
                    showingSave = true
                } label: {
                    Text("Next")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle())
                .padding(.vertical)
                .padding(.horizontal, 32)
                .accessibilityIdentifier("nextButton")
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
        .navigationInlineTitle("Review seed phrase")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if (onClose == nil) {
                    DismissButton(icon: .back)
                } else {
                    DismissButton(icon: .close, action: onClose)
                }
            }
        }
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
                seedPhrase: .bip39(words: words),
                ownerState: ownerState,
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
        LoggedInOwnerPreviewContainer {
            NavigationStack {
                SeedVerification(
                    words: ["sample", "word"],
                    ownerState: .sample,
                    isFirstTime: true,
                    onSuccess: {}
                ).foregroundColor(.Censo.primaryForeground)
            }
        }
        LoggedInOwnerPreviewContainer {
            NavigationStack {
                SeedVerification(
                    words: ["donor", "tower", "topic", "path", "obey", "intact", "lyrics", "list", "hair", "slice", "cluster", "grunt"],
                    ownerState: .sample,
                    isFirstTime: true,
                    onSuccess: {}
                )
            }
        }
    }
}
#endif
