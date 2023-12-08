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
    var onContinue: (API.TrustedApprover) -> Void
    
    @State private var selectedApprover: API.TrustedApprover?
    
    init(intent: API.Access.Intent, policy: API.Policy, selectedApprover: API.TrustedApprover? = nil, onContinue: @escaping (API.TrustedApprover) -> Void) {
        self.intent = intent
        self.policy = policy
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
                    Text("Request access")
                        .font(.title2)
                        .bold()
                
                    Text("""
                    Seed phrase access requires the assistance of \(
                        approvers.map { $0.label }.joined(separator: " or ")
                    ).
                    
                    This should preferably take place either on the phone or in-person to allow the approver to verify your identify.
                    
                    Select your approver below when you are speaking with them:
                    """)
                    .font(.subheadline)
                case .replacePolicy:
                    Text("Request approval")
                        .font(.title2)
                        .bold()
                
                    Text("""
                    Removing approvers requires the assistance of \(
                        approvers.map { $0.label }.joined(separator: " or ")
                    ).
                    
                    This should preferably take place either on the phone or in-person to allow the approver to verify your identify.
                    
                    Select your approver below when you are speaking with them:
                    """)
                    .font(.subheadline)
                }
                
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
        ChooseAccessApprover(
            intent: .accessPhrases,
            policy: .sample2Approvers,
            onContinue: { _ in }
        )
        .navigationTitle(Text("Access"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
