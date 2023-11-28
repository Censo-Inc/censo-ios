//
//  BiometryGatedScreen.swift
//  Censo
//
//  Created by Anton Onyshchenko on 27.09.23.
//

import Foundation
import SwiftUI
import Moya

struct BiometryGatedScreen<Content: View>: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.scenePhase) var scenePhase
    
    var session: Session
    @Binding var ownerState: API.OwnerState
    var onUnlockExpired: () -> Void
    @ViewBuilder var content: () -> Content
    
    @State private var showAuthentication = false
    
    private let prolongationThreshold: TimeInterval = 600
    @State var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            switch ownerState {
            case .ready(let ready):
                if let unlockedDuration = ready.unlockedForSeconds {
                        content()
                        .onChange(of: scenePhase) { newScenePhase in
                            switch newScenePhase {
                            case .active:
                                timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
                            case .inactive,
                                 .background:
                                timer.upstream.connect().cancel()
                            default:
                                break;
                            }
                        }
                        .onAppear {
                            showAuthentication = false
                        }
                        .onReceive(timer) { _ in
                            if (Date.now >= unlockedDuration.locksAt) {
                                onUnlockExpired()
                            } else {
                                if unlockedDuration.locksAt.timeIntervalSinceNow < prolongationThreshold {
                                    prolongUnlock()
                                }
                            }
                        }
                } else {
                    if showAuthentication {
                        switch ownerState.authType {
                        case .facetec:
                            FacetecAuth<API.UnlockApiResponse>(
                                session: session,
                                onReadyToUploadResults: { biometryVerificationId, biometryData in
                                    return .unlock(API.UnlockApiRequest(biometryVerificationId: biometryVerificationId, biometryData: biometryData))
                                },
                                onSuccess: { response in
                                    ownerState = response.ownerState
                                },
                                onCancelled: {
                                    showAuthentication = false
                                }
                            )
                        case .password:
                            GetPassword { cryptedPassword, onComplete in
                                apiProvider.decodableRequest(with: session, endpoint: .unlockWithPassword(API.UnlockWithPasswordApiRequest(password: API.Password(cryptedPassword: cryptedPassword)))) {
                                    (result: Result<API.UnlockWithPasswordApiResponse, MoyaError>) in
                                    switch result {
                                    case .failure(MoyaError.underlying(CensoError.validation("Incorrect password"), _)):
                                        onComplete(false)
                                    case .failure:
                                        showAuthentication = false
                                        onComplete(true)
                                    case .success(let response):
                                        ownerState = response.ownerState
                                        onComplete(true)
                                    }
                                }
                            }
                        case .none:
                            EmptyView().onAppear {
                                showAuthentication = false
                            }
                        }
                    } else {
                        LockScreen(
                            onReadyToAuthenticate: {
                                showAuthentication = true
                            }
                        )
                    }
                }
            default:
                content()
            }
        }
    }
    
    private func prolongUnlock() {
        apiProvider.decodableRequest(with: session, endpoint: .prolongUnlock) { (result: Result<API.ProlongUnlockApiResponse, MoyaError>) in
            switch result {
            case .success(let response):
                ownerState = response.ownerState
            case .failure:
                break
            }
        }
    }
}


#if DEBUG
#Preview("ReadyUnlocked") {
    let session = Session.sample
    
    @State var ownerState1 = API.OwnerState.ready(.init(policy: .sample, vault: .sample, unlockedForSeconds: UnlockedDuration(value: 600), authType: .facetec, subscriptionStatus: .active))
    return BiometryGatedScreen(
        session: session,
        ownerState: $ownerState1,
        onUnlockExpired: {}
    ) {
        VStack {
            Text("test")
        }
    }
}

#Preview("ReadyLocked") {
    let session = Session.sample
    @State var ownerState2 = API.OwnerState.ready(.init(policy: .sample, vault: .sample, unlockedForSeconds: nil, authType: .facetec, subscriptionStatus: .active))
    return BiometryGatedScreen(
        session: session,
        ownerState: $ownerState2,
        onUnlockExpired: {}
    ) {
        VStack {
            Text("test")
        }
    }
}

#Preview("Initial") {
    let session = Session.sample
    @State var ownerState3 = API.OwnerState.initial(API.OwnerState.Initial(authType: .facetec, subscriptionStatus: .active))
    return BiometryGatedScreen(
        session: session,
        ownerState: $ownerState3,
        onUnlockExpired: {}
    ) {
        VStack {
            Text("test")
        }
    }
}
#endif
