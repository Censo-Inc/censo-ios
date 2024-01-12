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
    
    var session: Session
    var policySetup: API.PolicySetup?
    var isPrimary: Bool
    var ownerEntropy: Base64EncodedString?
    var onComplete: () -> Void
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    var onBack: (() -> Void)?
    
    var body: some View {
        if let policySetup = policySetup, let approver = isPrimary ? policySetup.primaryApprover : policySetup.alternateApprover {
            ActivateApprover(
                session: session,
                policySetup: policySetup,
                approver: approver,
                onComplete: onComplete,
                onOwnerStateUpdated: onOwnerStateUpdated,
                onBack: onBack
            )
        } else {
            EnterApproverNickname(
                session: session,
                policySetup: policySetup,
                isPrimary: isPrimary,
                ownerEntropy: ownerEntropy,
                onComplete: onOwnerStateUpdated,
                onBack: onBack
            )
        }
    }
}
