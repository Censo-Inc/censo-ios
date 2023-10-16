//
//  EnsureICloud.swift
//  Vault
//
//  Created by Ben Holzman on 2023-10-06.
//

import SwiftUI
import CloudKit

struct EnsureICloud<Content>: View where Content : View {
    @Environment(\.scenePhase) var scenePhase
    @State private var accountStatus: CKAccountStatus?

    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack {
            switch accountStatus {
            case .none:
                ProgressView().onAppear(perform: {
                    getICloudAccountStatus()
                })
            case .some(let status):
                switch (status) {
                case .available:
                    content()
                case .noAccount:
                    Text("You will need to be logged in to an iCloud account to continue")
                case .restricted:
                    Text("An iCloud account is required, but your iCloud account is restricted")
                case .couldNotDetermine:
                    Text("An iCloud account is required, but we could not determine if you are logged in to iCloud")
                case .temporarilyUnavailable:
                    Text("An iCloud account is required, but your iCloud account is temporarily unavailable")
                @unknown default:
                    Text("An iCloud account is required, but we could not get your account status for an unknown reason")
                }
            }
        }.onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                getICloudAccountStatus()
            }
        }
    }

    private func getICloudAccountStatus() {
        CKContainer.default().accountStatus { (status, error) in
            accountStatus = status
            if (error != nil) {
                debugPrint(error!)
            }
        }
    }
}

