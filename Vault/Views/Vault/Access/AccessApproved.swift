//
//  AccessApproved.swift
//  Vault
//
//  Created by Anton Onyshchenko on 30.10.23.
//

import Foundation
import SwiftUI

struct AccessApproved : View {
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            
            HStack {
                Spacer()
                
                Image(systemName: "checkmark.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.black)
                    .frame(maxWidth: 162, maxHeight: 162)
                
                Spacer()
            }
            
            Text("Approved")
                .font(.system(size: 24))
                .bold()
                .padding([.leading, .trailing], 32)
                .padding([.top], 25)
                .padding([.bottom], 10)
            
            Spacer()
        }
        .frame(maxHeight: .infinity)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview {
    NavigationView {
        AccessApproved()
    }
}
#endif
