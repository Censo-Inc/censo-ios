//
//  BiometryGatedScreen.swift
//  Censo
//
//  Created by Anton Onyshchenko on 27.09.23.
//

import Foundation
import SwiftUI

struct BiometryGatedScreen<Content: View>: View {
    @Environment(\.scenePhase) var scenePhase
    
    @EnvironmentObject var ownerRepository: OwnerRepository
    @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController
    
    var ownerState: API.OwnerState
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
                        ownerState: ready
                    )
                }
            default:
                content()
            }
        }
    }
    
    private func prolongUnlock() {
        ownerRepository.prolongUnlock { result in
            switch result {
            case .success(let response):
                ownerStateStoreController.replace(response.ownerState)
            case .failure:
                break
            }
        }
    }
}


#if DEBUG
#Preview("ReadyUnlocked") {
    LoggedInOwnerPreviewContainer {
        BiometryGatedScreen(
            ownerState: API.OwnerState.ready(.init(
                policy: .sample,
                vault: .sample,
                unlockedForSeconds: UnlockedDuration(value: 600),
                authType: .facetec,
                subscriptionStatus: .active,
                timelockSetting: .sample,
                subscriptionRequired: true,
                onboarded: true,
                canRequestAuthenticationReset: false
            )),
            onUnlockExpired: {}
        ) {
            VStack {
                Text("test")
            }
        }
    }
}

#Preview("ReadyLocked") {
    LoggedInOwnerPreviewContainer {
        BiometryGatedScreen(
            ownerState: API.OwnerState.ready(.init(
                policy: .sample,
                vault: .sample,
                unlockedForSeconds: nil,
                authType: .facetec,
                subscriptionStatus: .active,
                timelockSetting: .sample,
                subscriptionRequired: true,
                onboarded: true,
                canRequestAuthenticationReset: false
            )),
            onUnlockExpired: {}
        ) {
            VStack {
                Text("test")
            }
        }
    }
}

#Preview("Initial") {
    LoggedInOwnerPreviewContainer {
        BiometryGatedScreen(
            ownerState: API.OwnerState.initial(API.OwnerState.Initial(
                authType: .facetec,
                entropy: .sample,
                subscriptionStatus: .active,
                subscriptionRequired: false
            )),
            onUnlockExpired: {}
        ) {
            VStack {
                Text("test")
            }
        }
    }
}
#endif
