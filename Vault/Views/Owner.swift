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

    @RemoteResult<API.User, API> private var user

    var session: Session

    var body: some View {
        switch user {
        case .idle:
            ProgressView()
                .onAppear(perform: reload)
        case .loading:
            ProgressView()
        case .success(let user):
            switch user.ownerState {
            case .none:
                PolicyAndGuardianSetup(session: session, onSuccess: reload)
            case .guardianSetup:
                PolicyAndGuardianSetup(session: session, onSuccess: reload)
            case .ready:
                List {
                    Text("Congrats!!")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(Color.green)
                    Spacer(minLength: 2)
                    Text("On the Vault screen now!!")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(Color.green)
                }.multilineTextAlignment(.center)
            }
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
