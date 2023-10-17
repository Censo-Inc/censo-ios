//
//  Welcome.swift
//  Vault
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
            Spacer()
            VStack(alignment: .leading) {
                Text("Welcome to Censo")
                    .font(.system(size: 24, weight: .semibold))
                    .padding()
                Text("We built Censo to be a secure way to safeguard your seed phrases with multiple levels of security:")
                    .font(.system(size: 18, weight: .medium))
                    .padding()
                
                VStack(alignment: .leading) {
                    SetupStep(image: Image("Apple"), heading: "Authenticate privately", content: "Censo does not store your info.", completionText: "Authenticated")
                    SetupStep(
                        image: Image("FaceScan"), heading: "Scan your face", content: "Fortify your Censo account with an encrypted, 3rd-party-verified scan.")
                    SetupStep(
                        image: Image("PhraseEntry"), heading: "Enter your seed phrase", content: "Add your seed phrase; Censo will encrypt it for your eyes only.")
                    Divider()
                    SetupStep(image: Image("TwoPeople"), heading: "Optional: Add approvers", content: "To improve security, choose people to approve access.")
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
                }
                .buttonStyle(RoundedButtonStyle())
                .padding()
                .frame(maxWidth: .infinity)
                
                HStack {
                    Image(systemName: "info.circle")
                    Text("Learn more")
                }
                .frame(maxWidth: .infinity)
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
    var body: some View {
        HStack(alignment: .center) {
            ZStack {
                Rectangle()
                    .fill(.gray)
                    .opacity(0.3)
                    .cornerRadius(18)
                image
            }.frame(width: 64, height: 64)
            VStack(alignment: .leading) {
                Text(heading)
                    .font(.system(size: 18))
                    .fontWeight(.bold)
                    .padding(.horizontal)
                    .padding(.vertical, -1)
                Text(content)
                    .font(.system(size: 14))
                    .padding(.leading)
                    .padding(.top, 1)
                switch (completionText) {
                case .some(let text):
                    Text("✓ " + text)
                        .font(.system(size: 14))
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .padding(.leading)
                        .padding(.top, 1)
                case .none:
                    EmptyView()
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
#Preview {
    Welcome(session: .sample, onComplete: {_ in })
}
#endif
