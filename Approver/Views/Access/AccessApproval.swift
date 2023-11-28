//
//  AccessApproval.swift
//  Accesss
//
//  Created by Brendan Flood on 9/29/23.
//

import SwiftUI
import Moya

struct AccessApproval: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss
    
    var session: Session
    var participantId: ParticipantId
    var approvalId: String?
    var onSuccess: () -> Void

    @RemoteResult<[API.GuardianState], API> private var guardianStates
    @State private var inProgress = false
    @State private var showLinkAccepted = true
    @State private var showGetLive = true
    @State private var showingError = false
    @State private var error: Error?

    @State private var refreshStatePublisher = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        switch guardianStates {
        case .idle:
            ProgressView()
                .onAppear(perform: reload)
        case .loading:
            ProgressView()
        case .success(let guardianStates):
            if let guardianState = guardianStates.forParticipantId(participantId) {
                switch guardianState.phase {
                case .recoveryRequested:
                    ProgressView()
                        .onAppear {
                            startOwnerVerification(participantId: guardianState.participantId)
                        }
                        .alert("Error", isPresented: $showingError, presenting: error) { _ in
                            Button {
                                dismiss()
                            } label: { Text("OK") }
                        } message: { error in
                            Text(error.localizedDescription)
                        }
                case .recoveryVerification, .recoveryConfirmation:
                    OwnerVerification(
                        session: session,
                        guardianState: guardianState,
                        approvalId: approvalId,
                        onGuardianStatesUpdated: replaceGuardianStates
                    )
                    .modifier(RefreshOnTimer(timer: $refreshStatePublisher, interval: 3, refresh: reload))
                case .complete:
                    OperationCompletedView(successText: "Congratulations. You're all done!\n\nThanks for helping someone keep their crypto safe.\n\nYou may now close the app.", onSuccess: onSuccess)
                        .navigationBarHidden(true)
                        .onAppear {
                            refreshStatePublisher.upstream.connect().cancel()
                        }
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
        _guardianStates.reload(
            with: apiProvider,
            target: session.target(for: .user),
            adaptSuccess: { (user: API.GuardianUser) in user.guardianStates }
        )
    }
    
    private func replaceGuardianStates(newGuardianStates: [API.GuardianState]) {
        _guardianStates.replace(newGuardianStates)
    }
    
    private func showError(_ error: Error) {
        showingError = true
        self.error = error
    }
    
    private func startOwnerVerification(participantId: ParticipantId) {
        do {
            let encryptedTotpSecret = try Base64EncodedString.encryptedTotpSecret(deviceKey: session.deviceKey)

            apiProvider.decodableRequest(
                with: session,
                endpoint: approvalId == nil ? .storeRecoveryTotpSecret(
                    participantId,
                    encryptedTotpSecret
                ) : .storeAccessTotpSecret(
                    approvalId!,
                    encryptedTotpSecret
                )
            ) { (result: Result<API.OwnerVerificationApiResponse, MoyaError>) in
                switch result {
                case .success(let success):
                    replaceGuardianStates(newGuardianStates: success.guardianStates)
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

struct InvalidLinkView : View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Text("Invalid link")
        }
        .multilineTextAlignment(.center)
        .navigationTitle(Text(""))
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                }
            }
        }
    }
}
