//
//  ContentView.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-09.
//

import SwiftUI

struct ContentView: View {
    @State private var session: SessionState = .idle

    enum SessionState {
        case idle
        case active(DeviceKey, Vault)
        case failedToActivate(Error)
    }

    var body: some View {
        switch session {
        case .idle:
            ProgressView()
                .onAppear(perform: reloadState)
        case .active(let deviceKey, let vault):
            ActiveSessionView(deviceKey: deviceKey, vault: vault, onSessionInvalidated: { error in
                session = .failedToActivate(error)
            })
        case .failedToActivate(let error as NSError) where error.domain == "com.apple.LocalAuthentication":
            BiometryFailed(onRetry: reloadState)
        case .failedToActivate(DeviceKey.DeviceKeyError.keyInvalidatedByBiometryChange):
            InvalidatedDeviceKeyView {
                do {
                    try SecureEnclaveWrapper.removeDeviceKey()
                    reloadState()
                } catch {
                    self.session = .failedToActivate(error)
                }
            }
        case .failedToActivate:
            Text("Something went wrong")
        }
    }

    private func reloadState() {
        #if DEBUG
        if CommandLine.isTesting {
            Keychain.removeVault()
            self.session = .active(.sample, Vault(entries: [:]))
            return
        }
        #endif

        if let deviceKey = SecureEnclaveWrapper.deviceKey() {
            deviceKey.preauthenticatedKey { result in
                switch result {
                case .success(let preauthenticatedKey):
                    do {
                        if let encryptedVault = try Keychain.encryptedVault() {
                            let vaultData = try preauthenticatedKey.decrypt(data: encryptedVault)
                            let vault = try JSONDecoder().decode(Vault.self, from: vaultData)
                            self.session = .active(deviceKey, vault)
                        } else {
                            self.session = .active(deviceKey, Vault(entries: [:]))
                        }
                    } catch {
                        self.session = .failedToActivate(error)
                    }
                case .failure(let error):
                    self.session = .failedToActivate(error)
                }
            }
        } else {
            do {
                let deviceKey = try SecureEnclaveWrapper.generateDeviceKey()
                self.session = .active(deviceKey, Vault(entries: [:]))
            } catch {
                self.session = .failedToActivate(error)
            }
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension CommandLine {
    static var isTesting: Bool = {
        arguments.contains("testing")
    }()
}

#endif
