//
//  PhraseAccessIntro.swift
//  Censo
//
//  Created by Brendan Flood on 10/25/23.
//

import SwiftUI

struct PhraseAccessIntro: View {
    var ownerState: API.OwnerState.Ready
    var onReadyToGetStarted: (WordListLanguage?) -> Void
    
    @State private var languageId: UInt8 = 0
    
    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 0) {
                Text("Ready to start your 15 minutes of access?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding()
                
                LanguageSelection(
                    text: Text(
                        "By default, your seed phrase is displayed in the language it was saved. You may select a different display language **here**"
                    )
                    .font(.subheadline),
                    languageId: $languageId
                )
                .padding(.horizontal)
                .padding(.bottom)
                
                VStack(alignment: .leading) {
                    SetupStep(image: Image("PrivatePlace"), heading: "Go to a private place", content: "Make sure you are alone in your home or a secure area.")
                    if ownerState.authType == .password {
                        SetupStep(
                            image: Image("PhraseEntry"), heading: "Enter your password", content: "Start your access by entering your password. If you leave the app you will need to enter your password again.")
                    } else {
                        SetupStep(
                            image: Image("FaceScan"), heading: "Scan your face", content: "Start your access with a face scan. If you leave the app you will need to scan your face again.")
                    }
                    SetupStep(
                        image: Image("Timer"), heading: "Access for 15 minutes", content: "You have 15 minutes to access your seed phrase. If you need more time, you will have to scan your face again.")
                }
                .padding(.horizontal)
                .padding(.vertical)
                
                Button {
                    onReadyToGetStarted(languageId == 0 ? nil : WordListLanguage.fromId(id: languageId))
                } label: {
                    Text("Get started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle())
                .padding()
                .accessibilityIdentifier("getStarted")
                
            }
            .padding()
        }
    }
}

struct SetupStep: View {
    var image: Image
    var heading: String
    var content: String
    var completionText: String?
    var opacity: Double = 0.3
    var body: some View {
        HStack(alignment: .center) {
            ZStack {
                Rectangle()
                    .fill(.gray)
                    .opacity(opacity)
                    .cornerRadius(18)
                image.renderingMode(.template)
            }.frame(width: 64, height: 64)
            VStack(alignment: .leading) {
                Text(heading)
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                    .padding(.vertical, -1)
                    .fixedSize(horizontal: true, vertical: true)
                Text(content)
                    .font(.footnote)
                    .padding(.leading)
                    .padding(.top, 1)
                    .fixedSize(horizontal: false, vertical: true)
                switch (completionText) {
                case .some(let text):
                    Text("✓ " + text)
                        .font(.footnote)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .padding(.leading)
                        .padding(.top, 1)
                case .none:
                    EmptyView()
                }
            }
        }
        .padding(.bottom)
    }
}

#if DEBUG
#Preview {
    NavigationView {
        PhraseAccessIntro(
            ownerState: .sample,
            onReadyToGetStarted: {_ in}
        )
        .foregroundColor(Color.Censo.primaryForeground)
    }
}
#endif
