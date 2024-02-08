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
    @State private var showInitialSetup = false
    @State private var getPromoCode = false
    @State private var promoCode = ""
    @State private var promoCodeAccepted = false
    @State private var showPromoCodeAccepted = false
    @State private var showingError = false
    @State private var error: Error?

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
                        
                        if (!promoCodeAccepted) {
                            Button {
                                getPromoCode = true
                            } label: {
                                Text("Have a promo code?")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(RoundedButtonStyle())
                            .accessibilityIdentifier("getPromoCode")
                        }
                        
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
                .sheet(isPresented: $getPromoCode) {
                    VStack {
                        TextField(text: $promoCode) {
                            Text("Enter promo code")
                                .padding()
                        }
                        .accessibilityIdentifier("promoCodeEntry")

                        Button {
                            submitPromoCode()
                        } label: {
                            Text("Submit")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(RoundedButtonStyle())
                        .accessibilityIdentifier("submitPromoCode")
                    }
                    .padding()
                    .textFieldStyle(RoundedTextFieldStyle())
                    .presentationDetents([.height(160)])
                }
                .alert("Error", isPresented: $showingError, presenting: error) { _ in
                    Button {
                        showingError = false
                        error = nil
                    } label: {
                        Text("OK")
                    }
                } message: { error in
                    Text(error.localizedDescription)
                }
                .alert("Promo code accepted!", isPresented: $showPromoCodeAccepted) {
                    Button {
                        promoCodeAccepted = true
                    } label: {
                        Text("OK")
                    }
                } message: {
                    Text("You'll get rewarded more when points arrive")
                }
            }
        }
    }

    func submitPromoCode() {
        getPromoCode = false
        let normalizedPromoCode = promoCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        apiProvider.request(with: session, endpoint: .setPromoCode(code: normalizedPromoCode)) { result in
            promoCode = ""
            switch result {
            case .success:
                showPromoCodeAccepted = true
            case .failure(let error):
                showingError = true
                self.error = error
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
