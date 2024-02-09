//
//  BeneficiaryActivated.swift
//  Censo
//
//  Created by Brendan Flood on 2/7/24.
//

import SwiftUI

struct BeneficiaryActivated: View {
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            
            HStack {
                Spacer()
                
                Image("CongratsFistBump")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(.horizontal)
                
                Spacer()
            }
            
            Text("Thanks for helping someone keep their crypto safe.")
                .font(.title2)
                .bold()
                .padding()
                .multilineTextAlignment(.center)
            
            Text("You may close the app now.")
                .font(.title2)
                .bold()
                .padding()
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .frame(maxHeight: .infinity)
        .navigationBarHidden(true)

    }
}

#if DEBUG
#Preview {
    BeneficiaryActivated()
}
#endif
