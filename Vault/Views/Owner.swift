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
    @State private var showApproversIntro = false
    @AppStorage("acceptedTermsOfUseVersion") var acceptedTermsOfUseVersion: String = ""

    var session: Session

    var body: some View {
        switch ownerStateResource {
        case .idle:
            ProgressView()
                .onAppear(perform: reload)
        case .loading:
            ProgressView()
        case .success(let ownerState):
            if (acceptedTermsOfUseVersion != "") {
                let ownerStateBinding = Binding<API.OwnerState>(
                    get: { ownerState },
                    set: { replaceOwnerState(newOwnerState: $0) }
                )
                BiometryGatedScreen(session: session, ownerState: ownerStateBinding, onUnlockExpired: reload) {
                    switch ownerState {
                    case .initial:
                        Welcome(
                            session: session,
                            onComplete: {ownerState in
                                replaceOwnerState(newOwnerState: ownerState)
                            }
                        )
                    case .ready(let ready) where ready.vault.secrets.isEmpty:
                        FirstPhrase(
                            ownerState: ready,
                            session: session,
                            onComplete: { ownerState in
                                showApproversIntro = true
                                replaceOwnerState(newOwnerState: ownerState)
                            }
                        )
                    case .ready(let ready):
                        VaultHomeScreen(
                            session: session,
                            ownerState: ready,
                            onOwnerStateUpdated: { _ in
                                reload()
                            }
                        )
                        .sheet(isPresented: $showApproversIntro, content: {
                            NavigationView {
                                InitialApproversSetup(
                                    session: session,
                                    ownerState: ready,
                                    onOwnerStateUpdated: replaceOwnerState
                                )
                            }
                        })
                    }
                }
            } else {
                NavigationStack {
                    TermsOfUse(
                        text: TermsOfUse.v0_1,
                        onAccept: {
                            acceptedTermsOfUseVersion = "v0.1"
                        }
                    )
                    .navigationTitle("Terms of Use")
                    .navigationBarTitleDisplayMode(.inline)
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

#if DEBUG
extension Base64EncodedString {
    static var sample: Self {
        try! .init(value: "")
    }
}

extension Session {
    static var sample: Self {
        .init(deviceKey: .sample, userCredentials: .sample)
    }
}

extension UserCredentials {
    static var sample: Self {
        .init(idToken: Data(), userIdentifier: "userIdentifier")
    }
}

extension API.PolicySetup {
    static var sample: Self {
        .init(guardians: [.sample], threshold: 2)
    }
}

extension API.ProspectGuardian {
    static var sample: Self {
        .init(invitationId: try! InvitationId(value: ""), label: "Jerry", participantId: .random(), status: .declined)
    }
}
#endif
