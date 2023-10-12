//
//  Owner.swift
//  Vault
//
//  Created by Ata Namvari on 2023-09-19.
//

import SwiftUI
import Moya

struct Owner: View {
    @Environment(\.apiProvider) var apiProvider

    @RemoteResult<API.OwnerState, API> private var ownerStateResource

    var session: Session

    var body: some View {
        switch ownerStateResource {
        case .idle:
            ProgressView()
                .onAppear(perform: reload)
        case .loading:
            ProgressView()
        case .success(let ownerState):
            let ownerStateBinding = Binding<API.OwnerState>(
                get: { ownerState },
                set: { replaceOwnerState(newOwnerState: $0) }
            )
            switch ownerState {
            case .initial:
                Welcome(
                    session: session,
                    onComplete: replaceOwnerState
                )
            case .guardianSetup(let guardianSetup):
                BiometryGatedScreen(session: session, ownerState: ownerStateBinding, onUnlockExpired: reload) {
                    ApproverActivation(
                        session: session,
                        guardianSetup: guardianSetup,
                        onOwnerStateUpdate: replaceOwnerState
                    )
                }
            case .guardianSetup(let guardianSetup) where guardianSetup.guardians.allConfirmed:
                BiometryGatedScreen(session: session, ownerState: ownerStateBinding, onUnlockExpired: reload) {
                    ApproversActivated(
                        session: session,
                        guardianSetup: guardianSetup,
                        onOwnerStateUpdate: replaceOwnerState
                    )
                }
            case .ready(let ready):
                BiometryGatedScreen(session: session, ownerState: ownerStateBinding, onUnlockExpired: reload) {
                    VaultHomeScreen(
                        session: session,
                        policy: ready.policy,
                        vault: ready.vault,
                        onOwnerStateUpdated: replaceOwnerState
                    )
                }
            }
        case .failure(MoyaError.statusCode(let response)) where response.statusCode == 404:
            SignIn(session: session, onSuccess: reload) {
                ProgressView("Signing in...")
            }
        case .failure(let error):
            RetryView(error: error, action: reload)
        }
    }

    private func replaceOwnerState(newOwnerState: API.OwnerState) {
        _ownerStateResource.replace(newOwnerState)
    }
    
    private func reload() {
        print("reload")
        _ownerStateResource.reload(
            with: apiProvider,
            target: session.target(for: .user),
            adaptSuccess: { (user: API.User) in user.ownerState }
        )
    }
}

extension Array where Element == API.ProspectGuardian {
    var allConfirmed: Bool {
        !contains { guardian in
            if case .confirmed = guardian.status {
                return false
            } else {
                return true
            }
        }
    }
}
