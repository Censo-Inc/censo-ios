//
//  BiometryGatedScreen.swift
//  Vault
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
    
    @State private var showFacetec = false
    
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
                            showFacetec = false
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
                    if showFacetec {
                        FacetecAuth<API.UnlockApiResponse>(
                            session: session,
                            onReadyToUploadResults: { biometryVerificationId, biometryData in
                                return .unlock(API.UnlockApiRequest(biometryVerificationId: biometryVerificationId, biometryData: biometryData))
                            },
                            onSuccess: { response in
                                ownerState = response.ownerState
                            }
                        )
                    } else {
                        LockScreen(
                            onReadyToStartFaceScan: {
                                showFacetec = true
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
    
    @State var ownerState1 = API.OwnerState.ready(.init(policy: .sample, vault: .sample, unlockedForSeconds: UnlockedDuration(value: 600)))
    return BiometryGatedScreen(
        session: session,
        ownerState: $ownerState1,
        onUnlockExpired: {}
    ) {
        RecoveredSecretsView(
            session: .sample,
            requestedSecrets: [],
            encryptedMasterKey: Base64EncodedString(data: Data()),
            deleteRecovery: {},
            status: RecoveredSecretsView.Status.showingSecrets(
                secrets: [
                    RecoveredSecretsView.RecoveredSecret(label: "Secret 1", secret: "Secret Phrase 1"),
                    RecoveredSecretsView.RecoveredSecret(label: "Secret 2", secret: "Secret Phrase 2"),
                ]
            )
        )
    }
}

#Preview("ReadyLocked") {
    let session = Session.sample
    @State var ownerState2 = API.OwnerState.ready(.init(policy: .sample, vault: .sample, unlockedForSeconds: nil))
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
    @State var ownerState3 = API.OwnerState.initial
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
