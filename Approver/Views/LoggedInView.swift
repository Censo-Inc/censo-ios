//
//  LoggedInApproverView.swift
//  Approver
//
//  Created by Anton Onyshchenko on 05.01.24.
//

import Foundation
import SwiftUI
import Moya

struct LoggedInView: View {
    @Environment(\.apiProvider) var apiProvider
    
    @RemoteResult<API.ApproverUser, API> private var user
    
    var session: Session
    var onUrlPasted: (URL) -> Void
    @Binding var reloadNeeded: Bool
    @Binding var showWelcome: Bool
    
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
                let userBinding = Binding<API.ApproverUser>(
                    get: { user },
                    set: { self._user.replace($0) }
                )
                if showWelcome {
                    LoggedInWelcomeScreen(
                        session: session,
                        user: userBinding,
                        onContinue: {
                            self.showWelcome = false
                        }
                    )
                } else {
                    ApproverHome(
                        session: session,
                        user: userBinding,
                        onUrlPasted: onUrlPasted
                    )
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden(true)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            DismissButton(icon: .back, action: {
                                self.showWelcome = true
                            })
                        }
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
    }
    
    private func reload() {
        _user.reload(with: apiProvider, target: session.target(for: .user))
    }
}
