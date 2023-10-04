//
//  LockedScreen.swift
//  Vault
//
//  Created by Anton Onyshchenko on 27.09.23.
//

import Foundation
import SwiftUI
import Moya

struct LockedScreen<Content: View>: View {
    @Environment(\.apiProvider) var apiProvider
    
    private let content: Content
    private var session: Session
    private var onOwnerStateUpdated: (API.OwnerState) -> Void
    private var onUnlockedTimeOut: () -> Void
    
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
        onUnlockedTimeOut: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.content = content()
        self.session = session
        self.onOwnerStateUpdated = onOwnerStateUpdated
        self.onUnlockedTimeOut = onUnlockedTimeOut
        self._lockState = State(initialValue: LockState(unlockedForSeconds))
    }
    
    var body: some View {
        VStack {
            switch (lockState) {
            case .locked:
                VStack {
                    VStack {
                        Text("Vault is locked")
                            .foregroundColor(.white)
                        Button {
                            lockState = .unlockInProgress
                        } label: {
                            Text("Unlock")
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                        }
                        .buttonStyle(BorderedButtonStyle(tint: .light))
                    }.padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.Censo.darkBlue)
            case .unlocked(let locksAt):
                VStack {
                    content
                    Spacer()
                    VStack {
                        LockCountDown(locksAt: locksAt, onTimeout: {
                            self.lockState = .locked
                            onUnlockedTimeOut()
                        })
                        Button {
                            lock()
                        } label: {
                            Text("Lock")
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .foregroundColor(.white)
                        }
                        .buttonStyle(BorderedButtonStyle(tint: .light))
                    }.padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.Censo.darkBlue)
            case .lockInProgress:
                VStack {
                    ProgressView()
                        .tint(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.Censo.darkBlue)
            case .lockFailed(let error):
                RetryView(error: error, action: { lock() })
            case .unlockInProgress:
                FacetecAuth(
                    session: session,
                    onReadyToUploadResults: { biomentryVerificationId, biometryData in
                        return .unlock(API.UnlockApiRequest(biometryVerificationId: biomentryVerificationId, biometryData: biometryData))
                    }, 
                    onSuccess: { ownerState in
                        updateLockState(ownerState: ownerState)
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
        Text("Locks in \(secondsRemaining) seconds")
            .font(Font.footnote)
            .foregroundStyle(.white)
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

#if DEBUG
struct LockedScreen_Previews: PreviewProvider {
    static var previews: some View {
        let session = Session(
            deviceKey: .sample,
            userCredentials: UserCredentials(idToken: Data(), userIdentifier: "")
        )
    
        LockedScreen(
            session,
            600,
            onOwnerStateUpdated: { _ in },
            onUnlockedTimeOut: {}
        ) {
            VStack {
                Text("test")
            }
        }
        
        LockedScreen(
            session,
            nil,
            onOwnerStateUpdated: { _ in },
            onUnlockedTimeOut: {}
        ) {
            VStack {
                Text("test")
            }
        }
    }
}
#endif
