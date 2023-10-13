//
//  AcceptInvitation.swift
//  Guardian
//
//  Created by Ben Holzman on 9/27/23.
//

import SwiftUI
import Moya

struct AcceptInvitation: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss

    var invitationId: InvitationId

    @State private var inProgress = false
    @State private var showingError = false
    @State private var currentError: Error?
    var session: Session

    var onSuccess: (API.GuardianState?) -> Void

    var body: some View {
        NavigationStack {
            InfoBoard {
                Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.")
            }
            .padding()
            Spacer()
            
            Button {
                acceptInvitation()
            } label: {
                if (inProgress) {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 44)
                } else {
                    Text("Get Started")
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .frame(height: 44)
                }
            }
            .padding()
            .buttonStyle(FilledButtonStyle())
            .disabled(inProgress)
        }
    }
    
    private func acceptInvitation() {
        inProgress = true
        apiProvider.decodableRequest(with: session, endpoint: .acceptInvitation(invitationId)) { (result: Result<API.AcceptInvitationApiResponse, MoyaError>) in
            switch result {
            case .success(let response):
                inProgress = false

                onSuccess(response.guardianState)
            case .failure(let error):
                showError(error)
            }
        }
    }

    private func showError(_ error: Error) {
        inProgress = false
        
        showingError = true
        currentError = error
    }
}


#if DEBUG
#Preview {
    AcceptInvitation(
        invitationId: "invitation_01hbbyesezf0kb5hr8v7f2353g",
        session: .sample, onSuccess: {_ in })
}

extension Session {
    static var sample: Self {
        .init(deviceKey: .sample, userCredentials: .sample)
    }
}

extension UserCredentials {
    static var sample: Self {
        .init(idToken: "012345".hexData()!, userIdentifier: "identifier")
    }
}

extension ParticipantId {
    static var sample: Self {
        try! .init(value: "2FdCBCBb8cE32e1d4D2c82BF0Ee7c6CDBfaB01DB3e9C5B2C0CccbE2CD4bFBa1f")
    }
}
#endif
