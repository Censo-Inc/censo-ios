//
//  LoggedInOwnerView.swift
//  Censo
//
//  Created by Ata Namvari on 2023-09-19.
//

import SwiftUI
import Moya

struct LoggedInOwnerView: View {
    @Environment(\.apiProvider) var apiProvider

    @RemoteResult<API.OwnerState, API> private var ownerStateResource
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
            if (acceptedTermsOfUseVersion == "v0.2") {
                let ownerStateBinding = Binding<API.OwnerState>(
                    get: { ownerState },
                    set: { replaceOwnerState(newOwnerState: $0) }
                )
                PaywallGatedScreen(session: session, ownerState: ownerStateBinding) {
                    BiometryGatedScreen(session: session, ownerState: ownerStateBinding, onUnlockExpired: reload) {
                        switch ownerState {
                        case .initial:
                            InitialPlanSetup(
                                session: session,
                                onComplete: replaceOwnerState
                            )
                        case .ready(let ready) where ready.vault.seedPhrases.isEmpty:
                            FirstPhrase(
                                ownerState: ready,
                                session: session,
                                onComplete: replaceOwnerState
                            )
                        case .ready(let ready):
                            HomeScreen(
                                session: session,
                                ownerState: ready,
                                onOwnerStateUpdated: { ownerState in
                                    replaceOwnerState(newOwnerState: ownerState)
                                    reload()
                                }
                            )
                        }
                    }
                }
            } else {
                NavigationStack {
                    TermsOfUse(
                        text: TermsOfUse.v0_2,
                        onAccept: {
                            acceptedTermsOfUseVersion = "v0.2"
                        }
                    )
                    .navigationTitle("Terms of Use")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        case .failure(MoyaError.underlying(CensoError.resourceNotFound, nil)):
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

extension Array where Element == API.ProspectApprover {
    var allConfirmed: Bool {
        !contains { approver in
            if case .confirmed = approver.status {
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
        .init(approvers: [.sample], threshold: 2)
    }
}

extension API.ProspectApprover {
    static var sample: Self {
        .init(invitationId: try! InvitationId(value: ""), label: "Jerry", participantId: .random(), status: .declined)
    }
}
#endif
