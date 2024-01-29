//
//  PendingAuthResetOnThisDevice.swift
//  Censo
//
//  Created by Anton Onyshchenko on 25.01.24.
//

import Foundation
import SwiftUI
import Moya

struct PendingAuthResetOnThisDevice : View {
    var session: Session
    var authType: API.AuthType
    var policy: API.Policy
    var authReset: API.AuthenticationReset.ThisDevice
    var onCancel: () -> Void
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    
    enum Step {
        case chooseApprover(selected: API.TrustedApprover?)
        case getApproval(approver: API.TrustedApprover)
    }
    
    @State private var step: Step = .chooseApprover(selected: nil)
    
    init(session: Session, authType: API.AuthType, policy: API.Policy, authReset: API.AuthenticationReset.ThisDevice, onCancel: @escaping () -> Void, onOwnerStateUpdated: @escaping (API.OwnerState) -> Void) {
        self.session = session
        self.authType = authType
        self.policy = policy
        self.authReset = authReset
        self.onCancel = onCancel
        self.onOwnerStateUpdated = onOwnerStateUpdated
        self._step = State(initialValue: .chooseApprover(selected: nil))
    }
    
    var body: some View {
        switch(step) {
        case .chooseApprover(let selected):
            ChooseAuthResetApprover(
                authType: authType,
                policy: policy,
                approvals: authReset.approvals,
                selectedApprover: selected,
                onContinue: { approver in
                    step = .getApproval(approver: approver)
                }
            )
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        onCancel()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            })
        case .getApproval(let approver):
            let approval = authReset.approvalForApprover(approver)!
            GetAuthResetApproval(
                session: session,
                authType: authType,
                policy: policy,
                approval: approval,
                approver: approver,
                onOwnerStateUpdated: onOwnerStateUpdated,
                onSuccess: {
                    if authReset.status != .approved {
                        step = .chooseApprover(selected: nil)
                    }
                }
            )
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        step = .chooseApprover(selected: approver)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
            })
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        let policy: API.Policy = .sample2Approvers
        
        PendingAuthResetOnThisDevice(
            session: .sample,
            authType: .facetec,
            policy: policy,
            authReset: API.AuthenticationReset.ThisDevice(
                guid: "",
                status: .requested,
                createdAt: Date(),
                expiresAt: Date(),
                approvals: policy.approvers.map({
                    return API.AuthenticationReset.ThisDevice.Approval(
                        guid: $0.participantId.value,
                        participantId: $0.participantId,
                        totpSecret: "35JV5AD2RJYIMH2J",
                        status: .initial
                    )
                })
            ),
            onCancel: {},
            onOwnerStateUpdated: { _ in }
        )
    }
    .foregroundColor(.Censo.primaryForeground)
}
#endif
