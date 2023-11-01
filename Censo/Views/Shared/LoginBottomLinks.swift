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
            Link(destination: URL(string: "https://censo.co/terms/")!, label: {
                Text("Terms")
                    .padding()
                    .fontWeight(.bold)
                    .tint(.black)
                    .frame(maxWidth: .infinity)
            })
            Link(destination: URL(string: "https://censo.co/privacy/")!, label: {
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
