//
//  SavedAndSharded.swift
//  Censo
//
//  Created by Anton Onyshchenko on 24.10.23.
//

import Foundation
import SwiftUI

struct ApproversSetupDone : View {
    var text: String
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            
            HStack {
                Spacer()
                
                Image(systemName: "checkmark.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 162, maxHeight: 162)
                
                Spacer()
            }
            
            Text(text)
                .font(.system(size: 24))
                .bold()
                .padding()

            Spacer()
        }
        .frame(maxHeight: .infinity)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview {
    NavigationView {
        ApproversSetupDone(text: "Activated")
    }
    .foregroundColor(Color.Censo.primaryForeground)
}
#endif
