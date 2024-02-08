//
//  Welcome.swift
//  Censo
//
//  Created by Ben Holzman on 1/22/24.
//

import SwiftUI

struct Welcome: View {
    var ownerState: API.OwnerState.Initial
    var onCancel: () -> Void
    @State var showInitialSetup = false
    
    var body: some View {
        if (showInitialSetup) {
            InitialPolicySetup(
                ownerState: ownerState,
                onCancel: { showInitialSetup = false }
            )
        } else {
            NavigationStack {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                    
                    Text("Welcome to Censo")
                        .font(.largeTitle)
                        .padding(.vertical)
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Censo is a breakthrough in seed phrase security. Here’s how you get started:")
                            .font(.headline)
                            .fontWeight(.medium)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom)
                    
                        Spacer().frame(maxHeight: 24)
                        
                        SetupStep(
                            image: Image("Apple"),
                            heading: "Authenticate privately",
                            content: "No personal info collected, ever, from Apple or any other source.",
                            completionText: "Authenticated"
                        )
                        Spacer().frame(maxHeight: 24)
                        SetupStep(
                            image: Image("FaceScan"),
                            heading: "Scan your face (optional)",
                            content: "Important operations can be secured by anonymous biometrics."
                        )
                        Spacer().frame(maxHeight: 24)
                        SetupStep(
                            image: Image("PhraseEntry"),
                            heading: "Enter your seed phrase",
                            content: "Now your seed phrase is encrypted and entirely in your control."
                        )
                        
                        Spacer()
                        
                        Button {
                            showInitialSetup = true
                        } label: {
                            Text("Get started")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(RoundedButtonStyle())
                        .accessibilityIdentifier("getStarted")
                    }
                    .padding(.vertical)
                }
                .padding(.horizontal, 32)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            onCancel()
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                })
            }
        }
    }
    
}

#if DEBUG
#Preview {
    LoggedInOwnerPreviewContainer {
        Welcome(
            ownerState: API.OwnerState.Initial(
                authType: .none,
                entropy: .empty,
                subscriptionStatus: .none,
                subscriptionRequired: false
            ),
            onCancel: {}
        )
    }
}
#endif
