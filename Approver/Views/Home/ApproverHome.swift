//
//  ApproverHome.swift
//  Approver
//
//  Created by Ata Namvari on 2023-09-13.
//

import SwiftUI
import Moya

struct ApproverHome: View {
    @Environment(\.apiProvider) var apiProvider
    
    @RemoteResult<API.GuardianUser, API> private var user
    
    var session: Session
    var onUrlPasted: (URL) -> Void
    @Binding var reloadNeeded: Bool
    
    var body: some View {
        if reloadNeeded {
            ProgressView().onAppear {
                reloadNeeded = false
                reload()
            }
        } else {
            switch user {
            case .idle:
                ProgressView()
                    .onAppear(perform: reload)
            case .loading:
                ProgressView()
            case .success(let user):
                LoggedInPasteLinkScreen(
                    session: session,
                    user: user,
                    onUrlPasted: onUrlPasted
                )
            case .failure(MoyaError.underlying(CensoError.resourceNotFound, nil)):
                SignIn(session: session, onSuccess: reload) {
                    ProgressView("Signing in...")
                }
            case .failure(let error):
                RetryView(error: error, action: reload)
            }
        }
    }
    
    private func reload() {
        _user.reload(with: apiProvider, target: session.target(for: .user))
    }
}

