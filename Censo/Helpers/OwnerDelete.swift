//
//  File.swift
//  Censo
//
//  Created by Ben Holzman on 1/25/24.
//

import Foundation
import Moya


func deleteOwner(apiProvider: MoyaProvider<API>, session: Session, ownerState: API.OwnerState, onSuccess: @escaping () -> Void, onFailure: @escaping (Error) -> Void) {
    apiProvider.request(with: session, endpoint: .deleteUser) { result in
        switch result {
        case .success:
            switch ownerState {
            case .ready(let ready):
                if let ownerTrustedApprover = ready.policy.approvers.first(where: { $0.isOwner }) {
                    session.deleteApproverKey(participantId: ownerTrustedApprover.participantId)
                }
                if let ownerProspectApprover = ready.policySetup?.owner {
                    session.deleteApproverKey(participantId: ownerProspectApprover.participantId)
                }
            case .initial:
                break
            }
            NotificationCenter.default.post(name: Notification.Name.deleteUserDataNotification, object: nil)
            onSuccess()
        case .failure(let error):
            onFailure(error)
        }
    }
}


