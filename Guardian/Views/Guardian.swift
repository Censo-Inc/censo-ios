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
                switch user.guardianStates.forInvite(inviteCode)?.phase {
                case .none:
                    VStack {
                        
                        List {
                            Text("You have been invited to act a guardian")
                                .frame(maxWidth: .infinity)
                            Spacer(minLength: 2)
                            Text("To complete the process, you should accept the invitation and connect with the inviter to be socially approved")
                                .frame(maxWidth: .infinity)
                        }.multilineTextAlignment(.center)
                        
                        HStack {
                            Button {
                                acceptInvitation()
                            } label: {
                                if (inProgress) {
                                    ProgressView()
                                } else {
                                    Text("Accept")
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .buttonStyle(FilledButtonStyle())
                            
                            
                            Spacer()
                            
                            Button {
                                confirmDecline = true
                            } label: {
                                Text("Decline")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(FilledButtonStyle())
                        }
                    }
                case .waitingForCode,
                        .waitingForConfirmation:
                    GuardianVerification(session: session, inviteCode: inviteCode, onSuccess: reload)
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
        .navigationBarTitle("Guardian Accept/Decline", displayMode: .inline)
        .padding()
        .alert("Error", isPresented: $showingError, presenting: currentError) { _ in
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: { error in
            Text(error.localizedDescription)
        }
        .alert("Warning", isPresented: $confirmDecline) {
            Button("Decline and continue", role: .destructive) {
                declineInvitation()
            }

            Button("OK", role: .cancel) {
                confirmDecline = false
            }
        } message: {
            Text("Are you sure you want to decline?")
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
    
    private func acceptInvitation() {
        inProgress = true
        apiProvider.request(with: session, endpoint: .acceptInvitation(inviteCode)) { result in
            switch result {
            case .success(let response) where response.statusCode < 400:
                inProgress = false
                reload()
            case .success(let response) where response.statusCode == 403:
                showError(GuardianError.alreadyUsed)
            case .success(let response):
                showError(MoyaError.statusCode(response))
            case .failure(let error):
                showError(error)
            }
        }
    }
    
    private func declineInvitation() {
        inProgress = true
        apiProvider.request(with: session, endpoint: .declineInvitation(inviteCode)) { result in
            switch result {
            case .success(let response) where response.statusCode < 400:
                dismiss()
            case .success(let response):
                showError(MoyaError.statusCode(response))
            case .failure(let error):
                showError(error)
            }
        }
    }
}



#if DEBUG
//struct GuardianView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
#endif
