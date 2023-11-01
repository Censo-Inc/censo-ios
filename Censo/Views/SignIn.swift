//
//  SignIn.swift
//  Censo
//
//  Created by Ata Namvari on 2023-09-19.
//

import SwiftUI
import Moya

struct SignIn<Content>: View where Content : View {
    @Environment(\.apiProvider) var apiProvider

    @State private var status: Status = .idle

    var session: Session
    var onSuccess: () -> Void

    @ViewBuilder var content: () -> Content

    enum Status {
        case idle
        case signingIn
        case failure(Error)
        case success
    }

    var body: some View {
        switch status {
        case .idle:
            content().onAppear(perform: signIn)
        case .signingIn:
            content()
        case .failure(let error):
            RetryView(error: error, action: signIn)
        case .success:
            content().onAppear(perform: onSuccess)
        }
    }

    private func signIn() {
        apiProvider.request(with: session, endpoint: .signIn(session.userCredentials)) { result in
            switch result {
            case .success(let response) where response.statusCode < 400:
                status = .success
            case .success(let response):
                status = .failure(MoyaError.statusCode(response))
            case .failure(let error):
                status = .failure(error)
            }
        }
    }
}
