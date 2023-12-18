//
//  Activated.swift
//  Censo
//
//  Created by Brendan Flood on 12/11/23.
//

import SwiftUI

struct Activated: View {
    var policy: API.Policy
    
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
                    .padding(.bottom, 40)
                
                VStack(spacing: 50) {
                    ForEach(Array(policy.externalApprovers.enumerated()), id: \.offset) { i, approver in
                        ApproverPill(isPrimary: true, approver: .trusted(approver))
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
            
        }
        .frame(maxHeight: .infinity)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview {
    Activated(
        policy: .sample2Approvers
    ).foregroundColor(.Censo.primaryForeground)
}
#endif
