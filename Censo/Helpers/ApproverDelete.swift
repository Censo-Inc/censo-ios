//
//  ApproverDelete.swift
//  Censo
//
//  Created by Ben Holzman on 1/25/24.
//

import Foundation
import Moya

func deleteApprover(apiProvider: MoyaProvider<API>, session: Session, onSuccess: @escaping () -> Void, onFailure: @escaping (Error) -> Void) {
    apiProvider.request(with: session, endpoint: .deleteUser) { result in
        switch result {
        case .success:
            NotificationCenter.default.post(name: Notification.Name.deleteUserDataNotification, object: nil)
            onSuccess()
        case .failure(let error):
            onFailure(error)
        }
    }
}


