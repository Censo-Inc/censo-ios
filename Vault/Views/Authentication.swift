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
    @State private var deviceKey: Result<DeviceKey, Error>?

    @ViewBuilder var content: (DeviceKey) -> Content

    var body: some View {
        switch credentialState {
        case .none:
            ProgressView()
                .onAppear(perform: fetchCredentialState)
        case .notFound,
             .revoked:
            Login(onSuccess: fetchCredentialState)
        case .authorized:
            switch deviceKey {
            case .none:
                Text("No DeviceKey")
            case .success(let deviceKey):
                content(deviceKey)
            case .failure:
                Text("There was an error generating a device key")
            }
        default:
            Text("Error")
        }
    }

    private func fetchCredentialState() {
        guard let userIdentifier = Keychain.userIdentifier else {
            self.credentialState = .notFound
            return
        }

        ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userIdentifier) { state, error in
            if let deviceKey = SecureEnclaveWrapper.deviceKey() {
                self.deviceKey = .success(deviceKey)
            } else {
                do {
                    let deviceKey = try SecureEnclaveWrapper.generateDeviceKey()
                    self.deviceKey = .success(deviceKey)
                } catch {
                    self.deviceKey = .failure(error)
                }
            }

            self.credentialState = state
        }
    }
}
