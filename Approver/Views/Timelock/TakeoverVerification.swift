//
//  TakeoverVerification.swift
//  Approver
//
//  Created by Brendan Flood on 2/14/24.
//

import SwiftUI
import Moya

struct TakeoverVerification: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss
    
    var session: Session
    var participantId: ParticipantId
    var takeoverId: TakeoverId
    var onSuccess: () -> Void

    @RemoteResult<[API.ApproverState], API> private var approverStates
    @State private var inProgress = false
    @State private var showLinkAccepted = true
    @State private var showGetLive = true
    @State private var showingError = false
    @State private var error: Error?

    @State private var refreshStatePublisher = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        switch approverStates {
        case .idle:
            ProgressView()
                .navigationBarHidden(true)
                .onAppear(perform: reload)
        case .loading:
            ProgressView()
                .navigationBarHidden(true)
        case .success(let approverStates):
            if let approverState = approverStates.forParticipantId(participantId) {
                switch approverState.phase {
                case .takeoverRequested:
                    ProgressView()
                        .navigationBarHidden(true)
                        .onAppear {
                            startBeneficiaryVerification()
                        }
                        .errorAlert(isPresented: $showingError, presenting: error) {
                            dismiss()
                        }
                case .takeoverVerification, .takeoverConfirmation:
                    BeneficiaryVerification(
                        session: session,
                        takeoverId: takeoverId,
                        approverState: approverState,
                        onApproverStatesUpdated: replaceApproverStates
                    )
                    .modifier(RefreshOnTimer(timer: $refreshStatePublisher, refresh: reload, isIdleTimerDisabled: true))
                case .complete:
                    OperationCompletedView(successText: "Thanks for helping someone keep their crypto safe.\n\nYou may now close the app.", showFistBump: false, onSuccess: onSuccess)
                        .navigationBarHidden(true)
                default:
                    InvalidLinkView()
                }
            } else {
                InvalidLinkView()
            }
        case .failure(MoyaError.underlying(CensoError.resourceNotFound, nil)):
            SignIn(session: session, onSuccess: reload) {
                ProgressView("Signing in...")
            }
        case .failure(let error):
            RetryView(error: error, action: reload)
        }
    }

    private func reload() {
        _approverStates.reload(
            with: apiProvider,
            target: session.target(for: .user),
            adaptSuccess: { (user: API.ApproverUser) in user.approverStates }
        )
    }
    
    private func replaceApproverStates(newApproverStates: [API.ApproverState]) {
        _approverStates.replace(newApproverStates)
    }
    
    private func showError(_ error: Error) {
        showingError = true
        self.error = error
    }
    
    private func startBeneficiaryVerification() {
        do {
            let encryptedTotpSecret = try Base64EncodedString.encryptedTotpSecret(deviceKey: session.deviceKey)

            apiProvider.decodableRequest(
                with: session,
                endpoint: .storeTakeoverTotpSecret(
                    takeoverId,
                    encryptedTotpSecret
                )
            ) { (result: Result<API.OwnerVerificationApiResponse, MoyaError>) in
                switch result {
                case .success(let success):
                    replaceApproverStates(newApproverStates: success.approverStates)
                case .failure(MoyaError.underlying(CensoError.resourceNotFound, nil)):
                    showError(CensoError.accessRequestNotFound)
                case .failure(let error):
                    showError(error)
                }
            }
        } catch {
            showError(error)
        }
    }
}
