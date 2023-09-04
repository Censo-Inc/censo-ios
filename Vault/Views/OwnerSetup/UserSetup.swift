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
        case .contact:
            ContactSetup { verification in
                onUpdate(user, .contactVerification(verification))
            }
        case .contactVerification(let pendingContactVerification):
            Verification(verification: pendingContactVerification, onBack: {
                onUpdate(user, .contact)
            }, onSuccess: reloadUser)
        case .faceTec(let contact):
            FacetecSetup(contact: contact, onSuccess: reloadUser)
        case .done:
            VStack(alignment: .leading) {
                Text("Success.")
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
        if contacts.count == 0 {
            return .contact
        }

        if biometricVerificationRequired, let contact = contacts.first {
            return .faceTec(contact)
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
