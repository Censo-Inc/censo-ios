//
//  SetupBeneficiary.swift
//  Censo
//
//  Created by Brendan Flood on 2/6/24.
//

import Foundation
import SwiftUI

struct SetupBeneficiary : View {
    @Environment(\.dismiss) var dismiss
    
    var policy: API.Policy
    
    var body: some View {
        NavigationStack {
            if let beneficiary = policy.beneficiary {
                ActivateBeneficiary(
                    beneficiary: beneficiary,
                    policy: policy
                )
            } else {
                EnterBeneficiaryNickname(
                    policy: policy
                )
            }
        }
    }
}

#if DEBUG
#Preview {
    LoggedInOwnerPreviewContainer {
        NavigationView {
            SetupBeneficiary(policy: .sample)
        }
    }
}
#endif
