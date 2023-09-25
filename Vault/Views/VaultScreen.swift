//
//  VaultScreen.swift
//  Vault
//
//  Created by Anton Onyshchenko on 22.09.23.
//

import Foundation
import SwiftUI
import Moya

struct VaultScreen: View {
    @Environment(\.apiProvider) var apiProvider
    
    var session: Session
    
    enum LockState {
        case locked
        case unlocked(locksInSeconds: UInt)
        case unlockInProgress
        case lockInProgress
        case lockFailed(error: Error)
        
        init(_ unlockedForSeconds: UInt?) {
            if unlockedForSeconds == nil {
                self = .locked
            } else {
                self = .unlocked(locksInSeconds: unlockedForSeconds!)
            }
        }
    }
    
    @State var lockState: LockState
    
    var refreshOwnerState: () -> Void
    
    var body: some View {
        VStack {
            switch (lockState) {
            case .locked:
                Text("Vault is locked")
                Button {
                    lockState = .unlockInProgress
                } label: {
                    Text("Unlock").frame(maxWidth: .infinity)
                }
                .buttonStyle(FilledButtonStyle())
            case .unlocked(let locksInSeconds):
                Text("Vault is unlocked")
                LockCountDown(secondsRemaining: locksInSeconds, onTimeout: {
                    self.lockState = .locked
                    refreshOwnerState()
                })
                Button {
                    unlock()
                } label: {
                    Text("Lock").frame(maxWidth: .infinity)
                }
                .buttonStyle(FilledButtonStyle())
            case .lockInProgress:
                ProgressView()
            case .lockFailed(let error):
                RetryView(error: error, action: { unlock() })
            case .unlockInProgress:
                FacetecAuth(
                    session: session,
                    onSuccess: { ownerState in
                        updateLockState(ownerState: ownerState)
                    },
                    onReadyToUploadResults: { biomentryVerificationId, biometryData in
                        return .unlock(API.UnlockApiRequest(biometryVerificationId: biomentryVerificationId, biometryData: biometryData))
                    }
                )
            }
        }
    }
    
    private func unlock() {
        lockState = .lockInProgress
        apiProvider.decodableRequest(with: session, endpoint: .lock) { (result: Result<API.LockApiResponse, MoyaError>) in
            switch result {
            case .success(let response):
                updateLockState(ownerState: response.ownerState)
            case .failure(let error):
                lockState = .lockFailed(error: error)
            }
        }
    }
    
    private func updateLockState(ownerState: API.OwnerState) {
        switch (ownerState) {
        case .ready(let ready):
            self.lockState = LockState(ready.unlockedForSeconds)
        default:
            break
        }
        refreshOwnerState()
    }
}


struct LockCountDown: View {
    @State var secondsRemaining: UInt = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var onTimeout: () -> Void
    
    var body: some View {
        VStack {
            Text("Locks in \(secondsRemaining) seconds")
        }
        .onReceive(timer) { time in
            if secondsRemaining > 0 {
                secondsRemaining -= 1
            } else {
                onTimeout()
            }
        }
    }
}
