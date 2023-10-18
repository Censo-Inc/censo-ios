//
//  Onboarded.swift
//  Guardian
//
//  Created by Brendan Flood on 10/17/23.
//

import SwiftUI

struct Onboarded: View {
    var body: some View {
        VStack(alignment: .center) {
            Text("You are fully set!")
                .font(.system(size: 24, weight: .bold))
                .padding()
            
            Text("When needed, the seed phrase owner will get in touch with you to approve their access")
                .font(.system(size: 18, weight: .medium))
                .padding()
        }.multilineTextAlignment(.center)
    }
}

#Preview {
    Onboarded()
}
