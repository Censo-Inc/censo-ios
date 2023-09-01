//
//  UserSetup.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-22.
//

import SwiftUI
import Moya

struct UserSetup: View {
    @Environment(\.apiProvider) var apiProvider

    var setupStep: GuardianSetup.SetupStep
    var user: API.User
    var onUpdate: (API.User, GuardianSetup.SetupStep) -> Void
    var onError: (Error) -> Void

    var body: some View {
        switch setupStep {

        case .email:
            EmailSetup(user: user, onBack: {
                onUpdate(user, .email)
            }, onSuccess: reloadUser)
        case .emailVerification(let contact):
            Verification(contact: contact, onBack: {
                onUpdate(user, .email)
            }, onSuccess: reloadUser)
        case .phone:
            PhoneSetup(user: user, onBack: {
                onUpdate(user, .email)
            }, onSuccess: reloadUser)
        case .phoneVerification(let contact):
            Verification(contact: contact, onBack: {
                onUpdate(user, .phone)
            }, onSuccess: reloadUser)
        case .done:
            EmptyView()
        }
    }

    private func reloadUser() {
        apiProvider.decodableRequest(.users) { (result: Result<API.User, MoyaError>) in
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
    var setupStep: GuardianSetup.SetupStep {
        switch (emailContact, phoneContact) {
        case (.none, .some(let contact)) where contact.verified:
            return .email
        case (.none, .none):
            return .email
        case (.some(let contact), .none) where !contact.verified:
            return .emailVerification(contact)
        case (.some, .none):
            return .phone
        case (.some, .some(let contact)) where !contact.verified,
            (.none, .some(let contact)):
            return .phoneVerification(contact)
        case (.some, .some):
            return .done
        }
    }

    var emailContact: API.Contact? {
        contacts.first(where: { $0.contactType == .email })
    }

    var phoneContact: API.Contact? {
        contacts.first(where: { $0.contactType == .phone })
    }
}
