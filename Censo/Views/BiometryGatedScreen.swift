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
    var reloadOwnerState: () -> Void
    var onUnlockExpired: () -> Void
    @ViewBuilder var content: () -> Content
    
    @State private var checkToggle = false
    
    private let prolongationThreshold: TimeInterval = 600
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            switch ownerState {
            case .ready(let ready):
                let unlockedDuration = ready.unlockedForSeconds ?? UnlockedDuration(value: 0)
                if Date.now < unlockedDuration.locksAt  {
                    content()
                        .onChange(of: scenePhase) { newScenePhase in
                            switch newScenePhase {
                            case .active:
                                if (Date.now >= unlockedDuration.locksAt) {
                                    checkToggle = !checkToggle
                                    onUnlockExpired()
                                }
                            default:
                                break;
                            }
                        }
                        .onReceive(timer) { _ in
                            if (Date.now >= unlockedDuration.locksAt) {
                                checkToggle = !checkToggle
                                if scenePhase == .active {
                                    onUnlockExpired()
                                }
                            } else {
                                if scenePhase == .active && unlockedDuration.locksAt.timeIntervalSinceNow < prolongationThreshold {
                                    prolongUnlock()
                                }
                            }
                        }
                } else {
                    LockScreen(
                        session: session,
                        ownerState: ready,
                        reloadOwnerState: reloadOwnerState,
                        onOwnerStateUpdated: {
                            ownerState = $0
                        }
                    )
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
    
    @State var ownerState1 = API.OwnerState.ready(.init(
        policy: .sample,
        vault: .sample,
        unlockedForSeconds: UnlockedDuration(value: 600),
        authType: .facetec,
        subscriptionStatus: .active,
        timelockSetting: .sample,
        subscriptionRequired: true,
        onboarded: true,
        canRequestAuthenticationReset: false
    ))
    return BiometryGatedScreen(
        session: session,
        ownerState: $ownerState1,
        reloadOwnerState: {},
        onUnlockExpired: {}
    ) {
        VStack {
            Text("test")
        }
    }
}

#Preview("ReadyLocked") {
    let session = Session.sample
    @State var ownerState2 = API.OwnerState.ready(.init(
        policy: .sample,
        vault: .sample,
        unlockedForSeconds: nil,
        authType: .facetec,
        subscriptionStatus: .active,
        timelockSetting: .sample,
        subscriptionRequired: true,
        onboarded: true,
        canRequestAuthenticationReset: false
    ))
    return BiometryGatedScreen(
        session: session,
        ownerState: $ownerState2,
        reloadOwnerState: {},
        onUnlockExpired: {}
    ) {
        VStack {
            Text("test")
        }
    }
    .foregroundColor(.Censo.primaryForeground)
}

#Preview("Initial") {
    let session = Session.sample
    @State var ownerState3 = API.OwnerState.initial(API.OwnerState.Initial(authType: .facetec, entropy: .sample, subscriptionStatus: .active, subscriptionRequired: false))
    return BiometryGatedScreen(
        session: session,
        ownerState: $ownerState3,
        reloadOwnerState: {},
        onUnlockExpired: {}
    ) {
        VStack {
            Text("test")
        }
    }
    .foregroundColor(.Censo.primaryForeground)
}
#endif
