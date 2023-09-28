//
//  ContentView.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-09.
//

import SwiftUI
import Moya

struct Guardian: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss

    @State private var confirmDecline = false
    @State private var completed = false
    @State private var inProgress = false
    @State private var showingError = false
    @State private var currentError: Error?
    
    @Binding var inviteCode: String
    
    @RemoteResult<API.GuardianUser, API> private var user

    @State var guardianState: API.GuardianState?

    var session: Session
    var onSuccess: () -> Void

    var body: some View {
        VStack {
            
            switch user {
            case .idle:
                ProgressView()
                    .onAppear(perform: reload)
            case .loading:
                ProgressView()
            case .success(let user):
                switch (guardianState ?? user.guardianStates.forInvite(inviteCode))?.phase {
                case .none:
                    AcceptInvitation(apiProvider: _apiProvider, dismiss: _dismiss, invitationId: inviteCode, session: session, onSuccess: {newState in guardianState = newState})
                case .waitingForCode:
                    SubmitVerification(
                        apiProvider: _apiProvider, invitationId: inviteCode, session: session, verificationStatus: .notSubmitted,
                                       onSuccess: {newState in guardianState = newState})
                case .waitingForConfirmation(let waitingForConfirmation):
                    SubmitVerification(
                        apiProvider: _apiProvider, invitationId: inviteCode,
                        session: session, verificationStatus: waitingForConfirmation.verificationStatus,
                        onSuccess: {newState in guardianState = newState})
                case .complete:
                    VStack {
                        List {
                            Text("Congratulations!!")
                                .frame(maxWidth: .infinity)
                            Text("You have completed onboarding.")
                                .frame(maxWidth: .infinity)
                            Text("You may close the app now.")
                                .frame(maxWidth: .infinity)
                        }.multilineTextAlignment(.center)
                        Button {
                            onSuccess()
                        } label: {
                            Text("OK").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(FilledButtonStyle())
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
        .multilineTextAlignment(.center)
        .navigationTitle(Text("Become an Approver"))
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showingError, presenting: currentError) { _ in
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: { error in
            Text(error.localizedDescription)
        }
    }

    private func reload() {
        _user.reload(with: apiProvider, target: session.target(for: .user))
    }
    
    private func showError(_ error: Error) {
        inProgress = false
        
        showingError = true
        currentError = error
    }
}



#if DEBUG
//struct GuardianView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
#endif
