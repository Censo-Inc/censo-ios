//
//  PendingAuthResetOnThisDevice.swift
//  Censo
//
//  Created by Anton Onyshchenko on 25.01.24.
//

import Foundation
import SwiftUI

struct PendingAuthResetOnThisDevice : View {
    var authType: API.AuthType
    var policy: API.Policy
    var authReset: API.AuthenticationReset.ThisDevice
    var onCancel: () -> Void
    
    enum Step {
        case chooseApprover(selected: API.TrustedApprover?)
        case getApproval(approver: API.TrustedApprover)
    }
    
    @State private var step: Step = .chooseApprover(selected: nil)
    
    init(authType: API.AuthType, policy: API.Policy, authReset: API.AuthenticationReset.ThisDevice, onCancel: @escaping () -> Void) {
        self.authType = authType
        self.policy = policy
        self.authReset = authReset
        self.onCancel = onCancel
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
                authType: authType,
                policy: policy,
                approval: approval,
                approver: approver,
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
    LoggedInOwnerPreviewContainer {
        NavigationStack {
            let policy: API.Policy = .sample2Approvers
            
            PendingAuthResetOnThisDevice(
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
                onCancel: {}
            )
        }
    }
}
#endif
