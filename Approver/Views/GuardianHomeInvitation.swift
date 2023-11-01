//
//  GuardianHomeInvitation.swift
//  Guardian
//
//  Created by Brendan Flood on 10/31/23.
//

import SwiftUI

struct GuardianHomeInvitation: View {
    
    var body: some View {
        VStack {
            Image("export")
            
            Text("Get the unique link")
                .font(.system(size: 24))
                .bold()
                .padding()
            
            Text("Please get the unique link from the seed phrase owner and tap on it, or paste it here.")
                .font(.system(size: 14))
                .padding()
        }
        .multilineTextAlignment(.center)
    }
}

#Preview {
    GuardianHomeInvitation()
}
