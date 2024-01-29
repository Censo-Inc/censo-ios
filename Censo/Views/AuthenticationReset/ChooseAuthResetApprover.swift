//
//  ChooseAuthResetApprover.swift
//  Censo
//
//  Created by Anton Onyshchenko on 25.01.24.
//

import Foundation
import SwiftUI

struct ChooseAuthResetApprover : View {
    var authType: API.AuthType
    var policy: API.Policy
    var approvals: [API.AuthenticationReset.ThisDevice.Approval]
    var onContinue: (API.TrustedApprover) -> Void
    
    @State private var selectedApprover: API.TrustedApprover?
    
    init(
        authType: API.AuthType,
        policy: API.Policy,
        approvals: [API.AuthenticationReset.ThisDevice.Approval],
        selectedApprover: API.TrustedApprover? = nil,
        onContinue: @escaping (API.TrustedApprover) -> Void
    ) {
        self.authType = authType
        self.policy = policy
        self.approvals = approvals
        self.onContinue = onContinue
        self._selectedApprover = State(initialValue: selectedApprover)
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(alignment: .leading, spacing: 20) {
                let approvers = policy.approvers
                    .filter({ !$0.isOwner })
                    .sorted(using: KeyPathComparator(\.attributes.onboardedAt))
                
                let resetType = authType == .facetec ? "Biometry" : "Password"
                
                Text("\(resetType) reset approval")
                    .font(.title2)
                    .bold()
                
                Text("""
                    \(resetType) reset requires the assistance from both of your approvers.
                    
                    This should preferably take place either on the phone or in-person to allow the approver to verify your identity.
                    
                    Select your approver to start with when you are speaking with them:
                    """)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
                
                VStack(spacing: 20) {
                    ForEach(Array(approvers.enumerated()), id: \.offset) { i, approver in
                        let isApproved = approvals.contains(where: { $0.participantId == approver.participantId && $0.status == .approved })
                        Button {
                            selectedApprover = approver
                        } label: {
                            ApproverPill(
                                isPrimary: i == 0,
                                approver: .trusted(approver),
                                isSelected: selectedApprover?.participantId == approver.participantId,
                                isDisabled: isApproved
                            )
                            .buttonStyle(PlainButtonStyle())
                        }
                        .disabled(isApproved)
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
                        .font(.title2)
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
        ChooseAuthResetApprover(
            authType: .facetec,
            policy: .sample2Approvers,
            approvals: API.Policy.sample2Approvers.approvers.map({
                API.AuthenticationReset.ThisDevice.Approval(
                    guid: $0.participantId.value,
                    participantId: $0.participantId,
                    totpSecret: "",
                    status: .initial
                )
            }),
            onContinue: { _ in }
        )
        .navigationTitle(Text("Biometry Reset"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
