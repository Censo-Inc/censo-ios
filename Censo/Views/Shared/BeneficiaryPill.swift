//
//  BeneficiaryPill.swift
//  Censo
//
//  Created by Brendan Flood on 2/6/24.
//

import SwiftUI

struct BeneficiaryPill: View {
    var beneficiary: API.Policy.Beneficiary
    var onVerificationSubmitted: ((API.Policy.Beneficiary.Status.VerificationSubmitted) -> Void)?
    var onActivated: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: "person.fill")
                .resizable()
                .scaledToFit()
                .padding([.trailing])
                .frame(maxHeight: 42)
            
            VStack(alignment: .leading) {
                Text(beneficiary.label)
                    .font(.title3)
                    .bold()
                
                Group {
                    switch beneficiary.status {
                    case .initial:
                        Text("Not yet verified")
                    case .accepted:
                        Text("Opened link in app")
                            .foregroundColor(.Censo.gray)
                    case .verificationSubmitted(let verificationSubmitted):
                        Text("Checking Code")
                            .foregroundColor(.Censo.gray)
                            .onAppear {
                                onVerificationSubmitted?(verificationSubmitted)
                            }
                    case .activated:
                        Text("Active")
                            .foregroundColor(Color.Censo.green)
                            .onAppear {
                                onActivated?()
                            }
                    }
                }
                .font(.subheadline)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 16.0)
                .stroke(Color.Censo.primaryForeground)
                .opacity(1.0)
        )
    }
}

#if DEBUG
extension API.Policy.Beneficiary {
    static var sample: Self {
        .init(label: "Ben Eficiary", 
              status: API.Policy.Beneficiary.Status.activated(API.Policy.Beneficiary.Status.Activated(confirmedAt: Date.now)
             )
        )
    }
    
    static var sampleAccepted: Self {
        .init(label: "Ben Eficiary",
              status: API.Policy.Beneficiary.Status.accepted(API.Policy.Beneficiary.Status.Accepted(
                deviceEncryptedTotpSecret: Base64EncodedString(data: Data()),
                acceptedAt: Date.now
              )
             )
        )
    }
    
}

#Preview {
    BeneficiaryPill(beneficiary: .sample)
        .foregroundColor(Color.Censo.primaryForeground)
}
#endif
