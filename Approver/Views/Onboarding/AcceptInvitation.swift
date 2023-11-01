//
//  AcceptInvitation.swift
//  Approver
//
//  Created by Ben Holzman on 9/27/23.
//

import SwiftUI
import Moya

struct AcceptInvitation: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss

    var invitationId: InvitationId

    @State private var showingError = false
    @State private var currentError: Error?
    @State private var inProgress = false
    @State private var guardianState: API.GuardianState?
    
    var session: Session
    var onSuccess: (API.GuardianState?) -> Void

    var body: some View {
        VStack {
            if let guardianState = self.guardianState {
                OperationCompletedView(successText: "Link accepted")
                    .navigationBarHidden(true)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            onSuccess(guardianState)
                        }
                    }
            } else {
                if inProgress {
                    ProgressView()
                        .alert("Error", isPresented: $showingError, presenting: currentError) { _ in
                            Button { 
                                inProgress = false
                            } label: { Text("OK") }
                        } message: { error in
                            Text(error.localizedDescription)
                        }
                } else {
                    ProgressView()
                        .onAppear {
                            acceptInvitation()
                        }
                }
                
            }
        }
        .multilineTextAlignment(.center)
        .navigationBarHidden(true)
    }
    
    private func acceptInvitation() {
        inProgress = true
        apiProvider.decodableRequest(with: session, endpoint: .acceptInvitation(invitationId)) { (result: Result<API.AcceptInvitationApiResponse, MoyaError>) in
            switch result {
            case .success(let response):
                guardianState = response.guardianState
            case .failure(let error):
                showError(error)
            }
        }
    }

    private func showError(_ error: Error) {
        showingError = true
        currentError = error
    }
}


#if DEBUG
#Preview {
    NavigationView {
        AcceptInvitation(
            invitationId: "invitation_01hbbyesezf0kb5hr8v7f2353g",
            session: .sample, onSuccess: {_ in })
    }
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
