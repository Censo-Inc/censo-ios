//
//  BeneficiaryWelcomeBack.swift
//  Censo
//
//  Created by Brendan Flood on 2/7/24.
//

import SwiftUI

struct BeneficiaryWelcomeBack: View {
    
    var body: some View {
        VStack(alignment: .leading) {
            
            Spacer()
            Text("Welcome back to Censo")
                .font(.largeTitle)
                .fontWeight(.bold)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical)
            
            Text("""
                You are the beneficiary for someone using Censo to secure their seed phrases.

                Using the button below, you can initiate the takeover process, which, once completed, will give you access to their crypto seed phrases, as well as any instructions they may have left.
                """
            )
            .font(.headline)
            .fontWeight(.regular)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical)
            
            Spacer()
            
            Button {
                
            } label: {
                Text("Initiate takeover")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            
            Spacer()
        }
        .padding()
        .padding()
    }
}

#if DEBUG
#Preview {
    LoggedInOwnerPreviewContainer {
        BeneficiaryWelcomeBack()
    }
}
#endif
