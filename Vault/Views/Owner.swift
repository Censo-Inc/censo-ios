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
            switch ownerState {
            case .initial:
                ApproversSetup(session: session) { newOwnerState in
                    _ownerStateResource.replace(newOwnerState)
                }
            case .guardianSetup:
                GuardianActivation(session: session, onSuccess: reload)
            case .ready(let ready):
                LockedScreen(session, ready.unlockedForSeconds, onOwnerStateUpdated: replaceOwnerState, onUnlockedTimeOut: reload) {
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
        _ownerStateResource.reload(
            with: apiProvider,
            target: session.target(for: .user),
            adaptSuccess: { (user: API.User) in user.ownerState }
        )
    }
}
