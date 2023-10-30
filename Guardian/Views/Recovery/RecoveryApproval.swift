//
//  ApproverRecovery.swift
//  Recovery
//
//  Created by Brendan Flood on 9/29/23.
//

import SwiftUI
import Moya

struct RecoveryApproval: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss

    @State private var inProgress = false
    @State private var showingError = false
    @State private var currentError: Error?
    
    @RemoteResult<API.GuardianUser, API> private var user

    var session: Session
    var participantId: ParticipantId
    var onSuccess: () -> Void
    
    @State private var refreshStatePublisher = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    private let remoteNotificationPublisher = NotificationCenter.default.publisher(for: .userDidReceiveRemoteNotification)

    var body: some View {
        VStack {
            switch user {
            case .idle:
                ProgressView()
                    .onAppear(perform: reload)
            case .loading:
                ProgressView()
            case .success(let user):
                let guardianState = user.guardianStates.forParticipantId(participantId)
                switch guardianState?.phase {
                case .recoveryRequested:
                    StartRecoveryApproval(
                        session: session,
                        guardianState: guardianState!,
                        onSuccess: reload)
                case .recoveryVerification:
                    OwnerVerification(
                        session: session,
                        guardianState: guardianState!,
                        onSuccess: reload
                    ).onReceive(refreshStatePublisher) { firedDate in
                        reload()
                    }.onReceive(remoteNotificationPublisher) { _ in
                        reload()
                    }
                case .recoveryConfirmation:
                    OwnerVerification(
                        session: session,
                        guardianState: guardianState!,
                        onSuccess: reload
                    )
                case .complete:
                    RecoveryApprovalComplete(onSuccess: onSuccess)
                        .navigationBarHidden(true) 
                        .onAppear {
                            refreshStatePublisher.upstream.connect().cancel()
                        }
                default:
                    Text("Invalid Recovery")
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
        .padding()
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

