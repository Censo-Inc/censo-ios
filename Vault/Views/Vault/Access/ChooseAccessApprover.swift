//
//  ChooseAccessApprover.swift
//  Vault
//
//  Created by Anton Onyshchenko on 30.10.23.
//

import Foundation
import SwiftUI

struct ChooseAccessApprover : View {
    var policy: API.Policy
    var onContinue: (API.TrustedGuardian) -> Void
    
    @State private var selectedApprover: API.TrustedGuardian?
    
    init(policy: API.Policy, selectedApprover: API.TrustedGuardian? = nil, onContinue: @escaping (API.TrustedGuardian) -> Void) {
        self.policy = policy
        self.onContinue = onContinue
        self._selectedApprover = State(initialValue: selectedApprover)
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(alignment: .leading, spacing: 30) {
                Text("Request access")
                    .font(.system(size: 24))
                    .bold()
                
                Text("Which approver would you like to use to request access?")
                    .font(.system(size: 14))
                
                let approvers = policy.guardians
                    .filter({ !$0.isOwner })
                    .sorted(using: KeyPathComparator(\.attributes.onboardedAt))
                
                VStack(spacing: 20) {
                    ForEach(Array(approvers.enumerated()), id: \.offset) { i, approver in
                        Button {
                            selectedApprover = approver
                        } label: {
                            ApproverPill(
                                isPrimary: i == 0,
                                approver: .trusted(approver),
                                isSelected: selectedApprover?.participantId == approver.participantId
                            )
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            Divider()
            
            VStack {
                Button {
                    if let selectedApprover {
                        onContinue(selectedApprover)
                    }
                } label: {
                    Text("Continue")
                        .font(.system(size: 24))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle())
                .disabled(selectedApprover == nil)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 32)
        }
    }
}

#if DEBUG
#Preview {
    NavigationView {
        ChooseAccessApprover(
            policy: .sample2Approvers,
            onContinue: { _ in }
        )
    }
}
#endif
