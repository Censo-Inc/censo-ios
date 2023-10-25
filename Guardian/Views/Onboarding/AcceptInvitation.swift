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
    @State private var showCancelAlert = false
    var session: Session

    var onSuccess: (API.GuardianState?) -> Void

    var body: some View {
        VStack {
            
            Text("You have been invited to become an approver!")
                .padding()
                .font(.headline)
            
            Button {
                acceptInvitation()
            } label: {
                if (inProgress) {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 44)
                } else {
                    Text("Accept Invitation")
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .frame(height: 44)
                }
            }
            .padding()
            .buttonStyle(RoundedButtonStyle())
            .disabled(inProgress)
            
            Button {
               showCancelAlert = true
            } label: {
                Text("Close")
            }
            .padding()
        }
        .alert("Error", isPresented: $showingError, presenting: currentError) { _ in
            Button { } label: { Text("OK") }
        } message: { error in
            Text(error.localizedDescription)
        }
        .alert("", isPresented: $showCancelAlert) {
            Button("Yes", role: .cancel) {
                dismiss()
            }
            Button("No") {}
        } message: {
            Text("Do you really want to cancel?")
        }
        .multilineTextAlignment(.center)
        .navigationTitle(Text(""))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                BackButton()
            }
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
