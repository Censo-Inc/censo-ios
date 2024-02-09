//
//  BeneficiaryLoggedOutWelcome.swift
//  Censo
//
//  Created by Brendan Flood on 2/7/24.
//

import SwiftUI

struct BeneficiaryLoggedOutWelcome: View {
    
    var onContinue: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            
            Text("Welcome to Censo")
                .font(.largeTitle)
                .fontWeight(.bold)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical)
            
            Text("""
                You’ve been chosen to be the beneficiary for someone using Censo to secure their seed phrases.

                The setup process is simple, anonymous, secure, and will only take a few minutes of your time.
                """
            )
            .font(.headline)
            .fontWeight(.regular)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical)
            
            Spacer()
            
            Button {
                onContinue()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            .padding(.bottom)
            .padding(.bottom)
        }
        .padding()
        .padding()
    }
}

#if DEBUG
#Preview {
    BeneficiaryLoggedOutWelcome(onContinue: {})
        .foregroundColor(.Censo.primaryForeground)
}
#endif
