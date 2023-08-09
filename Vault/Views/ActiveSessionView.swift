//
//  ActiveSessionView.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-09.
//

import SwiftUI

struct ActiveSessionView: View {
    @State private var obfuscated = false

    var deviceKey: DeviceKey
    var vault: Vault
    var onSessionInvalidated: (Error) -> Void

    var body: some View {
        PhraseList(vaultStorage: VaultStorage(vault: vault, deviceKey: deviceKey))
            .blur(radius: obfuscated ? 20 : 0)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                obfuscated = true
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                obfuscated = false
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                reloadSession()
            }
    }

    private func reloadSession() {
        deviceKey.preauthenticatedKey { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                onSessionInvalidated(error)
            }
        }
    }
}
