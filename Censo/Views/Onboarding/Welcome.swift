//
//  Welcome.swift
//  Censo
//
//  Created by Ben Holzman on 10/10/23.
//

import SwiftUI

struct Welcome: View {
    @Environment(\.apiProvider) var apiProvider

    var session: Session
    var onComplete: (API.OwnerState) -> Void
    
    var body: some View {
        NavigationStack {
            Spacer(minLength: 5)
            VStack(alignment: .leading) {
                Text("Welcome to Censo")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                Text("Censo is a breakthrough in seed phrase security. Here’s how you get started:")
                    .font(.headline)
                    .fontWeight(.medium)
                    .padding()
                
                VStack(alignment: .leading) {
                    SetupStep(image: Image("Apple"), heading: "Authenticate anonymously", content: "No personal info collected, ever, from Apple or any other source.", completionText: "Authenticated")
                    SetupStep(
                        image: Image("FaceScan"), heading: "Scan your face", content: "Biometrics ensure that only you have access to your seed phrase.")
                    SetupStep(
                        image: Image("PhraseEntry"), heading: "Enter your seed phrase", content: "Now your seed phrase is encrypted and entirely in your control.")
                    Divider()
                    SetupStep(image: Image("TwoPeople"), heading: "Optional: Add approvers", content: "Provide additional security through safety in numbers.")
                    Divider()
                }
                .padding()
                
                NavigationLink {
                    InitialPlanSetup(
                        session: session,
                        onComplete: onComplete
                    )
                } label: {
                    Text("Get started")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle())
                .padding(.horizontal)
                
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
                image
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
        .padding(.vertical, 4)
    }
}

#if DEBUG
#Preview {
    Welcome(session: .sample, onComplete: {_ in })
}
#endif
