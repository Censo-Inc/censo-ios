//
//  SetupApprover.swift
//  Censo
//
//  Created by Anton Onyshchenko on 24.10.23.
//

import Foundation
import SwiftUI

struct SetupApprover : View {
    @Environment(\.dismiss) var dismiss
    
    var policySetup: API.PolicySetup?
    var isPrimary: Bool
    var onComplete: () -> Void
    var onBack: (() -> Void)?
    
    var body: some View {
        if let policySetup = policySetup, let approver = isPrimary ? policySetup.primaryApprover : policySetup.alternateApprover {
            ActivateApprover(
                policySetup: policySetup,
                approver: approver,
                onComplete: onComplete,
                onBack: onBack
            )
        } else {
            EnterApproverNickname(
                policySetup: policySetup,
                isPrimary: isPrimary,
                onBack: onBack
            )
        }
    }
}
