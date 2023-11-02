//
//  ContentView.swift
//  Censo
//
//  Created by Ata Namvari on 2023-08-09.
//

import SwiftUI
import Moya

struct Onboarding: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss

    @State private var confirmDecline = false
    @State private var completed = false
    @State private var inProgress = false
    @State private var showingError = false
    @State private var currentError: Error?
    
    var inviteCode: String
    
    @RemoteResult<API.GuardianUser, API> private var user

    @State var guardianState: API.GuardianState?

    var session: Session
    var onSuccess: () -> Void

    var body: some View {
        NavigationStack {
            
            switch user {
            case .idle:
                ProgressView()
                    .onAppear(perform: reload)
            case .loading:
                ProgressView()
            case .success(let user):
                let currentState = guardianState ?? user.guardianStates.forInvite(inviteCode)
                switch currentState?.phase {
                case .none:
                    AcceptInvitation(
                        invitationId: inviteCode,
                        session: session,
                        onSuccess: {newState in guardianState = newState}
                    )
                case .waitingForCode,
                     .waitingForVerification,
                    . verificationRejected:
                    SubmitVerification(
                        invitationId: inviteCode, 
                        session: session,
                        guardianState: currentState!,
                        onSuccess: {newState in guardianState = newState}
                    )
                    .navigationBarBackButtonHidden(true)
                case .complete:
                    OperationCompletedView(successText: "Code accepted")
                        .navigationBarHidden(true)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                onSuccess()
                            }
                        }
                default:
                    EmptyView()
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
        .navigationTitle(Text(""))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                BackButton()
            }
        }
        .alert("Error", isPresented: $showingError, presenting: currentError) { _ in
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: { error in
            Text(error.localizedDescription)
        }
    }

    private func reload() {
        guardianState = nil
        _user.reload(with: apiProvider, target: session.target(for: .user))
    }
    
    private func showError(_ error: Error) {
        inProgress = false
        
        showingError = true
        currentError = error
    }
}

