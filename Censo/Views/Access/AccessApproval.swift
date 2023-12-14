//
//  AccessApproval.swift
//  Censo
//
//  Created by Anton Onyshchenko on 27.10.23.
//

import Foundation
import SwiftUI
import Moya

struct AccessApproval : View {
    @Environment(\.dismiss) var dismiss
    
    var session: Session
    var policy: API.Policy
    var access: API.Access.ThisDevice
    var onCancel: () -> Void
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    
    enum Step {
        case chooseApprover(selected: API.TrustedApprover?)
        case enterTotp(approver: API.TrustedApprover)
        case approved(ownerState: API.OwnerState)
    }
    
    @State private var step: Step = .chooseApprover(selected: nil)
    
    init(session: Session, policy: API.Policy, access: API.Access.ThisDevice, onCancel: @escaping () -> Void, onOwnerStateUpdated: @escaping (API.OwnerState) -> Void) {
        self.session = session
        self.policy = policy
        self.access = access
        self.onCancel = onCancel
        self.onOwnerStateUpdated = onOwnerStateUpdated
        self._step = State(initialValue: .chooseApprover(selected: nil))
    }
    
    var body: some View {
        let navigationTitle: String = switch (access.intent) {
        case .accessPhrases: "Access"
        case .replacePolicy: "Remove approvers"
        }
        
        switch(step) {
        case .chooseApprover(let selected):
            ChooseAccessApprover(
                intent: access.intent,
                policy: policy,
                selectedApprover: selected,
                onContinue: { approver in
                    step = .enterTotp(approver: approver)
                }
            )
            .navigationTitle(Text(navigationTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        onCancel()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
            })
        case .enterTotp(let approver):
            let approval = access.approvals.first(where: {$0.participantId == approver.participantId})!
            EnterAccessVerificationCode(
                session: session,
                policy: policy,
                approval: approval,
                approver: approver,
                intent: access.intent,
                onOwnerStateUpdated: onOwnerStateUpdated,
                onSuccess: { ownerState in
                    step = .approved(ownerState: ownerState)
                }
            )
            .navigationTitle(Text(navigationTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        step = .chooseApprover(selected: approver)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
            })
        case .approved(let ownerState):
            AccessApproved()
                .onAppear(perform: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        onOwnerStateUpdated(ownerState)
                    }
                })
        }
    }
}


extension API.OwnerState {
    var thisDeviceAccess: API.Access.ThisDevice? {
        get {
            guard case let .ready(ready) = self,
                  let access = ready.access,
                  case let .thisDevice(thisDeviceAccess) = access
            else { return nil }
            
            return thisDeviceAccess
        }
    }
}

