//
//  LockUnlockWrapper.swift
//  Vault
//
//  Created by Anton Onyshchenko on 27.09.23.
//

import Foundation
import SwiftUI
import Moya

struct LockUnlockWrapper<Content: View>: View {
    @Environment(\.apiProvider) var apiProvider
    
    private let content: Content
    private var session: Session
    private var onOwnerStateUpdated: (API.OwnerState) -> Void
    private var onUnlockTimeOut: () -> Void
    
    enum LockState {
        case locked
        case unlocked(locksAt: Date)
        case unlockInProgress
        case lockInProgress
        case lockFailed(error: Error)
        
        init(_ unlockedForSeconds: UInt?) {
            if unlockedForSeconds == nil {
                self = .locked
            } else {
                self = .unlocked(
                    locksAt: Date.now.addingTimeInterval(Double(unlockedForSeconds!))
                )
            }
        }
    }
    
    @State private var lockState: LockState
    
    init(
        _ session: Session,
        _ unlockedForSeconds: UInt?,
        onOwnerStateUpdated: @escaping (API.OwnerState) -> Void,
        onUnlockTimeOut: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.content = content()
        self.session = session
        self.onOwnerStateUpdated = onOwnerStateUpdated
        self.onUnlockTimeOut = onUnlockTimeOut
        self._lockState = State(initialValue: LockState(unlockedForSeconds))
    }
    
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
            case .unlocked(let locksAt):
                content
                Spacer()
                LockCountDown(locksAt: locksAt, onTimeout: {
                    self.lockState = .locked
                    onUnlockTimeOut()
                })
                Button {
                    lock()
                } label: {
                    Text("Lock").frame(maxWidth: .infinity)
                }
                .buttonStyle(FilledButtonStyle())
            case .lockInProgress:
                ProgressView()
            case .lockFailed(let error):
                RetryView(error: error, action: { lock() })
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
    
    private func lock() {
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
        onOwnerStateUpdated(ownerState)
    }
}


struct LockCountDown: View {
    var locksAt: Date
    @State var secondsRemaining: UInt = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var onTimeout: () -> Void
    
    var body: some View {
        VStack {
            Text("Locks in \(secondsRemaining) seconds")
        }
        .onAppear {
            secondsRemaining = UInt(locksAt.timeIntervalSinceNow)
        }
        .onReceive(timer) { time in
            if (Date.now >= locksAt) {
                onTimeout()
            } else {
                secondsRemaining = UInt(locksAt.timeIntervalSinceNow)
            }
        }
    }
}
