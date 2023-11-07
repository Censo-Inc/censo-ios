//
//  LoginBottomLinks.swift
//  Censo
//
//  Created by Brendan Flood on 10/31/23.
//

import SwiftUI

struct LoginBottomLinks: View {
    var body: some View {
        HStack {
            Link(destination: Configuration.termsOfServiceURL, label: {
                Text("Terms")
                    .padding()
                    .fontWeight(.bold)
                    .tint(.black)
                    .frame(maxWidth: .infinity)
            })
            Link(destination: Configuration.privacyPolicyURL, label: {
                Text("Privacy")
                    .padding()
                    .fontWeight(.bold)
                    .tint(.black)
                    .frame(maxWidth: .infinity)
            })
        }
    }
}

#if DEBUG
#Preview {
    VStack {
        Spacer()
        LoginBottomLinks()
    }
}
#endif
