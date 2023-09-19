//
//  Authentication.swift
//  Vault
//
//  Created by Ata Namvari on 2023-09-18.
//

import SwiftUI
import AuthenticationServices

struct Authentication<Content>: View where Content : View {
    @State private var credentialState: ASAuthorizationAppleIDProvider.CredentialState?
    @State private var session: Result<Session, Error>?

    @ViewBuilder var content: (Session) -> Content

    var body: some View {
        switch credentialState {
        case .none:
            ProgressView()
                .onAppear(perform: fetchCredentialState)
        case .notFound,
             .revoked:
            Login(onSuccess: fetchCredentialState)
        case .authorized:
            switch session {
            case .none:
                Text("No DeviceKey")
            case .success(let session):
                content(session)
            case .failure:
                Text("There was an error generating a device key")
            }
        default:
            Text("Error")
        }
    }

    private func fetchCredentialState() {
        guard let userCredentials = Keychain.userCredentials else {
            self.credentialState = .notFound
            return
        }

        ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userCredentials.userIdentifier) { state, error in
            if let deviceKey = SecureEnclaveWrapper.deviceKey(userIdentifier: userCredentials.userIdentifier) {
                self.session = .success(Session(deviceKey: deviceKey, userCredentials: userCredentials))
            } else {
                do {
                    let deviceKey = try SecureEnclaveWrapper.generateDeviceKey(userIdentifier: userCredentials.userIdentifier)
                    self.session = .success(Session(deviceKey: deviceKey, userCredentials: userCredentials))
                } catch {
                    self.session = .failure(error)
                }
            }

            self.credentialState = state
        }
    }
}
