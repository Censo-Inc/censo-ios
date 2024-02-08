//
//  PromoCodeEntry.swift
//  Censo
//
//  Created by Ben Holzman on 1/22/24.
//

import SwiftUI

struct PromoCodeEntry: View {
    @Environment(\.apiProvider) var apiProvider
    var session: Session
    var onPromoCodeAccepted: () -> Void
    @State private var promoCode = ""
    @State private var getPromoCode = false
    @State private var showPromoCodeAccepted = false
    @State private var showingError = false
    @State private var error: Error?
    
    var body: some View {
        VStack {
            Button {
                getPromoCode = true
            } label: {
                Text("Have a promo code?")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            .accessibilityIdentifier("getPromoCode")
        }
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
                        .font(.headline)
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
                onPromoCodeAccepted()
            } label: {
                Text("OK")
            }
        } message: {
            Text("You'll get rewarded more when points arrive")
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
    PromoCodeEntry(session: .sample, onPromoCodeAccepted: {})
}
#endif
