//
//  UserSetup.swift
//  Vault
//
//  Created by Ata Namvari on 2023-09-06.
//

import SwiftUI
import Moya

struct UserSetup: View {
    @Environment(\.apiProvider) var apiProvider

    var setupStep: OwnerSetup.SetupStep
    var user: API.User
    var onUpdate: (API.User, OwnerSetup.SetupStep) -> Void
    var onError: (Error) -> Void

    var body: some View {
        switch setupStep {
        case .signIn:
            SignIn(onSuccess: reloadUser)
        case .faceTec(let userGuid):
            FacetecSetup(userGuid: userGuid, onSuccess: reloadUser)
        case .policyAndGuardianSetup:
            PolicyAndGuardianSetup(onSuccess: reloadUser)
        case .done:
            VStack(alignment: .leading) {
                Text("Phrase Entry goes here!")
            }
        }
    }

    private func reloadUser() {
        apiProvider.decodableRequest(.user) { (result: Result<API.User, MoyaError>) in
            switch result {
            case .success(let user):
                onUpdate(user, user.setupStep)
            case .failure(let error):
                onError(error)
            }
        }
    }
}

extension API.User {
    var setupStep: OwnerSetup.SetupStep {
        
        if ownerState == nil {
            return .policyAndGuardianSetup
        }
        
        switch (ownerState!) {
        case .guardianSetup:
            return .policyAndGuardianSetup
        default: break;
        }

        return .done
    }
}

#if DEBUG
struct OwnerSetup_Previews: PreviewProvider {
    static var previews: some View {
        OwnerSetup()
    }
}
#endif
