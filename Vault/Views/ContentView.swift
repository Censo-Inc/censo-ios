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
        case active(DeviceKey)
        case failedToActivate(Error)
    }

    var body: some View {
        switch session {
        case .idle:
            ProgressView()
                .onAppear(perform: reloadState)
        case .active(let deviceKey):
            OwnerSetup()
        case .failedToActivate:
            Text("Something went wrong")
        }
    }

    private func reloadState() {
        #if DEBUG
        if CommandLine.isTesting {
            self.session = .active(.sample)
            return
        }
        #endif

        if let deviceKey = SecureEnclaveWrapper.deviceKey() {
            self.session = .active(deviceKey)
        } else {
            do {
                let deviceKey = try SecureEnclaveWrapper.generateDeviceKey()
                self.session = .active(deviceKey)
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
