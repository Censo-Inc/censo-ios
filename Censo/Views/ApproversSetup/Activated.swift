//
//  Activated.swift
//  Censo
//
//  Created by Brendan Flood on 12/11/23.
//

import SwiftUI

struct Activated: View {
    var body: some View {
        ZStack(alignment: .center) {
        
            Image("Confetti")
                .resizable()
                .aspectRatio(contentMode: .fit)
            
            VStack {
                Spacer()
                Text("Activated!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
            }
            
        }
        .frame(maxHeight: .infinity)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview {
    Activated().foregroundColor(.Censo.primaryForeground)
}
#endif
