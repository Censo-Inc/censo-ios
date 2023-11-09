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
    
    var body: some View {
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
                onUrlPasted: onUrlPasted,
                onDeleted: reload
            )
        case .failure(MoyaError.statusCode(let response)) where response.statusCode == 404:
            SignIn(session: session, onSuccess: reload) {
                ProgressView("Signing in...")
            }
        case .failure(let error):
            RetryView(error: error, action: reload)
        }
    }
    
    private func reload() {
        _user.reload(with: apiProvider, target: session.target(for: .user))
    }
}

