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
