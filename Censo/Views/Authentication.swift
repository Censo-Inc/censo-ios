//
//  Authentication.swift
//  Censo
//
//  Created by Ata Namvari on 2023-09-18.
//

import SwiftUI
import AuthenticationServices
import Sentry

extension Notification.Name {
    static let deleteUserDataNotification = Notification.Name("DeleteUserDataNotification")
    static let maintenanceStatusCheckNotification = Notification.Name("MaintenanceStatusCheckNotification")
}

struct Authentication<LoggedOutContent, LoggedInContent>: View where LoggedOutContent : View, LoggedInContent : View {
    @Environment(\.scenePhase) var scenePhase
    @State private var credentialState: ASAuthorizationAppleIDProvider.CredentialState?
    @State private var session: Result<Session, Error>?

    @ViewBuilder var loggedOutContent: (@escaping () -> Void) -> LoggedOutContent
    @ViewBuilder var loggedInContent: (Session) -> LoggedInContent

    var body: some View {
        switch credentialState {
        case .none:
            ProgressView()
                .onAppear(perform: fetchCredentialState)
        case .notFound, .revoked:
            loggedOutContent(fetchCredentialState)
        case .authorized:
            switch session {
            case .none:
                Text("No DeviceKey")
            case .success(let session):
                loggedInContent(session)
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name.deleteUserDataNotification)) { _ in
                    session.deleteDeviceKey()
                    Keychain.removeUserCredentials()
                    UserDefaults.standard.removeObject(forKey: "attestKey-\(session.userCredentials.userIdentifier)")
                    self.credentialState = .notFound
                }
                .onChange(of: scenePhase) { newPhase in
                    switch newPhase {
                    case .active:
                        fetchCredentialState()
                    default:
                        break
                    }
                }
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
            switch error {
            case .some(let error):
                SentrySDK.captureWithTag(error: error, tagValue: "Authentication")
            case .none:
                break
            }
            if let deviceKey = SecureEnclaveWrapper.deviceKey(userIdentifier: userCredentials.userIdentifier) {
                self.session = .success(Session(deviceKey: deviceKey, userCredentials: userCredentials))
            } else {
                do {
                    let deviceKey = try SecureEnclaveWrapper.generateDeviceKey(userIdentifier: userCredentials.userIdentifier)
                    self.session = .success(Session(deviceKey: deviceKey, userCredentials: userCredentials))
                } catch {
                    SentrySDK.captureWithTag(error: error, tagValue: "Generate Device Key")
                    self.session = .failure(error)
                }
            }

            self.credentialState = state
        }
    }
}
