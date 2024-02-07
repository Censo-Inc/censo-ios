//
//  ChooseAccessApprover.swift
//  Censo
//
//  Created by Anton Onyshchenko on 30.10.23.
//

import Foundation
import SwiftUI

struct ChooseAccessApprover : View {
    var intent: API.Access.Intent
    var policy: API.Policy
    var approvals: [API.Access.ThisDevice.Approval]
    var onContinue: (API.TrustedApprover) -> Void
    
    @State private var selectedApprover: API.TrustedApprover?
    
    init(
        intent: API.Access.Intent,
        policy: API.Policy,
        approvals: [API.Access.ThisDevice.Approval],
        selectedApprover: API.TrustedApprover? = nil,
        onContinue: @escaping (API.TrustedApprover) -> Void
    ) {
        self.intent = intent
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
                
                switch (intent) {
                case .accessPhrases:
                    Text("""
                    Seed phrase access requires the assistance of \(
                        approvers.map { $0.label }.joined(separator: " or ")
                    ).
                    
                    This should preferably take place either on the phone or in-person to allow the approver to verify your identity.
                    
                    Select your approver below when you are speaking with them:
                    """)
                    .font(.subheadline)
                case .replacePolicy:
                    Text("""
                    This will make you the sole approver when complete, and allow you to optionally add new approvers.
                    """)
                    .font(.subheadline)
                    
                    Text("""
                    Removing approvers requires the assistance of \(
                        approvers.map { $0.label }.joined(separator: " or ")
                    ).
                    
                    This should preferably take place either on the phone or in-person to allow the approver to verify your identity.
                    
                    Select your approver below when you are speaking with them:
                    """)
                    .font(.subheadline)
                case .recoverOwnerKey:
                    Text("""
                    Key recovery requires the assistance from both of your approvers.
                    
                    This should preferably take place either on the phone or in-person to allow the approver to verify your identity.
                    
                    Select your approver to start with when you are speaking with them:
                    """)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                }
                
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
                        .font(.headline)
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
            intent: .accessPhrases,
            policy: .sample2Approvers,
            approvals: API.Policy.sample2Approvers.approvers.map({
                API.Access.ThisDevice.Approval(
                    participantId: $0.participantId,
                    approvalId: $0.participantId.value,
                    status: .initial
                )
            }),
            onContinue: { _ in }
        )
        .navigationTitle(Text("Access"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
