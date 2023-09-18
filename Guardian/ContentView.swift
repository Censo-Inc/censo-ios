//
//  ContentView.swift
//  Guardian
//
//  Created by Ata Namvari on 2023-09-13.
//

import SwiftUI
import Moya

struct ContentView: View {
    enum Registration {
        case registeredDevice(DeviceKey)
        case unregisteredDevice
    }

    @Environment(\.apiProvider) var apiProvider

    @State private var inviteCode: String = ""
    @State private var inProgress = false
    @State private var registration: Registration = {
        SecureEnclaveWrapper.deviceKey().flatMap { deviceKey in
            .registeredDevice(deviceKey)
        } ?? .unregisteredDevice
    }()

    @State private var showingError = false
    @State private var currentError: Error?

    @State private var showingWarning = false
    @State private var attemptingURL: URL?

    var body: some View {
        Group {
            switch registration {
            case .registeredDevice(let deviceKey):
                GuardianSetup(deviceKey: deviceKey)
                    .onOpenURL { url in
                        showingWarning = true
                        attemptingURL = url
                    }
            case .unregisteredDevice:
                Invitation(inviteCode: $inviteCode, onValidateCode: registerDevice)
                    .disabled(inProgress)
                    .onOpenURL(perform: openURL)
            }
        }
        .alert("Error", isPresented: $showingError, presenting: currentError) { _ in
            Button("OK", role: .cancel, action: {})
        } message: { error in
            Text(error.localizedDescription)
        }
        .alert("Warning", isPresented: $showingWarning, presenting: attemptingURL) { url in
            Button("Decline and continue", role: .destructive) {
                try? SecureEnclaveWrapper.removeDeviceKey()
                registration = .unregisteredDevice
                openURL(url)
                // ADD: Send and forget API call to decline invite
            }

            Button("OK", role: .cancel) {}
        } message: { _ in
            Text("You must finish current request before accepting a new one.")
        }

    }

    private func openURL(_ url: URL) {
        guard url.pathComponents.count > 1,
            let action = url.pathComponents.first,
            action == "invite" else {
            return
        }

        self.inviteCode = url.pathComponents[1]

        registerDevice()
    }

    private func showError(_ error: Error) {
        self.currentError = error
        self.showingError = true
    }

    private func registerDevice() {
        inProgress = true

        do {
            if let _ = SecureEnclaveWrapper.deviceKey() {
                try SecureEnclaveWrapper.removeDeviceKey()
            }

            let deviceKey = try SecureEnclaveWrapper.generateDeviceKey()

            apiProvider.request(.registerDevice(inviteCode: inviteCode, deviceKey: deviceKey)) { result in
                self.inProgress = false

                switch result {
                case .success(let response) where response.statusCode < 400:
                    self.registration = .registeredDevice(deviceKey)
                case .success(let response):
                    try? SecureEnclaveWrapper.removeDeviceKey()
                    showError(MoyaError.statusCode(response))
                case .failure(let error):
                    try? SecureEnclaveWrapper.removeDeviceKey()
                    showError(error)
                }
            }
        } catch {
            showError(error)
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
