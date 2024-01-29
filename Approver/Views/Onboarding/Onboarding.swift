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
    
    @RemoteResult<API.ApproverUser, API> private var user

    @State var approverState: API.ApproverState?

    var session: Session
    var inviteCode: String
    var onSuccess: () -> Void

    var body: some View {
        NavigationStack {
            switch user {
            case .idle:
                ProgressView()
                    .navigationBarHidden(true)
                    .onAppear(perform: reload)
            case .loading:
                ProgressView()
                    .navigationBarHidden(true)
            case .success(let user):
                if let currentState = approverState ?? user.approverStates.forInvite(inviteCode) {
                    switch currentState.phase {
                    case .waitingForCode, .waitingForVerification, .verificationRejected:
                        SubmitVerification(
                            intent: .onboarding(inviteCode),
                            session: session,
                            approverState: currentState,
                            onSuccess: { updatedApproverStates in
                                approverState = updatedApproverStates.forInvite(inviteCode)
                            }
                        )
                        .navigationBarHidden(true)
                    case .complete:
                        // we require to label the owner unless it is the first owner for this approver
                        if user.approverStates.hasOther(currentState.participantId) && currentState.ownerLabel == nil {
                            LabelOwner(
                                session: session,
                                participantId: currentState.participantId,
                                label: currentState.ownerLabel,
                                onComplete: { newState in
                                    self.approverState = nil
                                    self._user.replace(newState)
                                }
                            )
                        } else {
                            OperationCompletedView(
                                successText: "Congratulations. You're all done!\n\nThanks for helping \(currentState.ownerLabel ?? "someone") keep their crypto safe.\n\nYou may now close the app.",
                                onSuccess: onSuccess
                            )
                            .navigationBarHidden(true)
                        }
                    default:
                        EmptyView()
                    }
                } else {
                    ProgressView()
                        .navigationBarHidden(true)
                        .onAppear {
                            acceptInvitation(invitationId: inviteCode)
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
        .multilineTextAlignment(.center)
        .navigationTitle(Text(""))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(isComplete)
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
    
    private var isComplete: Bool {
        get {
            if let approverState = approverState {
                return .complete == approverState.phase
            } else if case let .success(user) = user {
                return .complete == user.approverStates.forInvite(inviteCode)?.phase
            }
            return false
        }
    }
    
    private func acceptInvitation(invitationId: String) {
        inProgress = true
        apiProvider.decodableRequest(with: session, endpoint: .acceptInvitation(invitationId)) { (result: Result<API.AcceptInvitationApiResponse, MoyaError>) in
            switch result {
            case .success(let response):
                approverState = response.approverState
            case .failure(MoyaError.underlying(CensoError.resourceNotFound, nil)):
                showError(CensoError.invitationNotFound)
            case .failure(MoyaError.underlying(CensoError.unauthorized, nil)):
                showError(CensoError.invitationAlreadyAccepted)
            case .failure(let error):
                showError(error)
            }
        }
    }

    private func reload() {
        approverState = nil
        _user.reload(with: apiProvider, target: session.target(for: .user))
    }
    
    private func showError(_ error: Error) {
        inProgress = false
        
        showingError = true
        currentError = error
    }
}

