//
//  Activated.swift
//  Censo
//
//  Created by Brendan Flood on 12/11/23.
//

import SwiftUI

struct Activated: View {
    var policy: API.Policy
    var isApprovers: Bool = true
    
    var body: some View {
        ZStack(alignment: .center) {
        
            Image("Confetti")
                .resizable()
                .aspectRatio(contentMode: .fit)
            
            VStack {
                Spacer()
                Text("\(isApprovers ? "Approvers" : "Beneficiary") activated!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 40)
                
                if isApprovers {
                    VStack(spacing: 50) {
                        ForEach(Array(policy.externalApprovers.enumerated()), id: \.offset) { i, approver in
                            ApproverPill(approver: .trusted(approver))
                        }
                    }
                    .padding(.horizontal, 32)
                } else {
                    if let beneficiary = policy.beneficiary {
                        BeneficiaryPill(beneficiary: beneficiary)
                            .padding(.horizontal, 32)
                    }
                }
                
                Spacer()
            }
            
        }
        .frame(maxHeight: .infinity)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview("Approvers") {
    Activated(
        policy: .sample2Approvers
    ).foregroundColor(.Censo.primaryForeground)
}

#Preview("Beneficiary") {
    Activated(
        policy: .sample2ApproversAndBeneficiary,
        isApprovers: false
    ).foregroundColor(.Censo.primaryForeground)
}
#endif
