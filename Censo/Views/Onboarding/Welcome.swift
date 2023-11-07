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
    @Binding var ownerState: API.OwnerState
    
    var body: some View {
        NavigationStack {
            Spacer(minLength: 5)
            VStack(alignment: .leading, spacing: 0) {
                Text("Welcome to Censo")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                    .padding(.bottom)
                Text("Censo is a breakthrough in seed phrase security. Here’s how you get started:")
                    .font(.headline)
                    .fontWeight(.medium)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal)
                    .padding(.bottom)
                
                VStack(alignment: .leading) {
                    SetupStep(
                        image: Image("Apple"),
                        heading: "Authenticate anonymously",
                        content: "No personal info collected, ever, from Apple or any other source.",
                        completionText: "Authenticated"
                    )
                    SetupStep(
                        image: Image("FaceScan"), 
                        heading: "Scan your face",
                        content: "Anonymous biometrics ensure that only you can access your seed phrase.",
                        completionText: {
                            if case .ready = ownerState {
                                return "Completed"
                            } else {
                                return nil
                            }
                        }()
                    )
                    SetupStep(
                        image: Image("PhraseEntry"), 
                        heading: "Enter your seed phrase",
                        content: "Now your seed phrase is encrypted and entirely in your control."
                    )
                    
                    Divider()
                        .padding(.bottom)
                    
                    SetupStep(
                        image: Image("TwoPeople"),
                        heading: "Optional: Add approvers",
                        content: "Provide additional security through safety in numbers."
                    )
                    
                    Divider()
                        .padding(.bottom)
                
                    NavigationLink {
                        InitialPlanSetup(
                            session: session,
                            onComplete: { newOwnerState in
                                ownerState = newOwnerState
                            }
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
            .padding(.horizontal)
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
        .padding(.bottom)
    }
}

#if DEBUG
#Preview {
    Welcome(session: .sample, ownerState: .constant(API.OwnerState.initial))
}
#endif
