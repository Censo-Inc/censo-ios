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
    var recovery: API.Recovery.ThisDevice
    var onCancel: () -> Void
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    
    enum Step {
        case chooseApprover(selected: API.TrustedGuardian?)
        case enterTotp(approver: API.TrustedGuardian)
        case approved(ownerState: API.OwnerState)
    }
    
    @State private var step: Step = .chooseApprover(selected: nil)
    
    init(session: Session, policy: API.Policy, recovery: API.Recovery.ThisDevice, onCancel: @escaping () -> Void, onOwnerStateUpdated: @escaping (API.OwnerState) -> Void) {
        self.session = session
        self.policy = policy
        self.recovery = recovery
        self.onCancel = onCancel
        self.onOwnerStateUpdated = onOwnerStateUpdated
        self._step = State(initialValue: .chooseApprover(selected: nil))
    }
    
    var body: some View {
        switch(step) {
        case .chooseApprover(let selected):
            ChooseAccessApprover(
                policy: policy,
                selectedApprover: selected,
                onContinue: { approver in
                    step = .enterTotp(approver: approver)
                }
            )
            .navigationTitle(Text("Access"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        onCancel()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                    }
                }
            })
        case .enterTotp(let approver):
            let approval = recovery.approvals.first(where: {$0.participantId == approver.participantId})!
            EnterAccessVerificationCode(
                session: session,
                policy: policy,
                approval: approval,
                approver: approver,
                onOwnerStateUpdated: onOwnerStateUpdated,
                onSuccess: { ownerState in
                    step = .approved(ownerState: ownerState)
                }
            )
            .navigationTitle(Text("Access"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        step = .chooseApprover(selected: approver)
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
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
    var thisDeviceRecovery: API.Recovery.ThisDevice? {
        get {
            guard case let .ready(ready) = self,
                  let recovery = ready.recovery,
                  case let .thisDevice(thisDeviceRecovery) = recovery 
            else { return nil }
            
            return thisDeviceRecovery
        }
    }
}

