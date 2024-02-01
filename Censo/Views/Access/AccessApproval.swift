//
//  AccessApproval.swift
//  Censo
//
//  Created by Anton Onyshchenko on 27.10.23.
//

import Foundation
import SwiftUI

struct AccessApproval : View {
    @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController
    
    var access: API.Access.ThisDevice
    var policy: API.Policy
    
    var onCancel: () -> Void
    
    enum Step {
        case chooseApprover(selected: API.TrustedApprover?)
        case enterTotp(approver: API.TrustedApprover)
        case approved(ownerState: API.OwnerState)
    }
    
    @State private var step: Step = .chooseApprover(selected: nil)
    
    var body: some View {
        let navigationTitle: String = switch (access.intent) {
        case .accessPhrases: "Access"
        case .replacePolicy: "Remove approvers"
        case .recoverOwnerKey: "Key recovery"
        }
        
        switch(step) {
        case .chooseApprover(let selected):
            ChooseAccessApprover(
                intent: access.intent,
                policy: policy,
                approvals: access.approvals,
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
                policy: policy,
                approval: approval,
                approver: approver,
                intent: access.intent,
                onSuccess: { ownerState in
                    if let access = ownerState.thisDeviceAccess, access.isApproved {
                        step = .approved(ownerState: ownerState)
                    } else {
                        ownerStateStoreController.replace(ownerState)
                        step = .chooseApprover(selected: nil)
                    }
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
                        ownerStateStoreController.replace(ownerState)
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

