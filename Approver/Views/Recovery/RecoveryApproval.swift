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
    @State private var showGetLive = true
    
    @RemoteResult<[API.GuardianState], API> private var guardianStates

    var session: Session
    var participantId: ParticipantId
    var onSuccess: () -> Void
    
    @State private var refreshStatePublisher = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    private let remoteNotificationPublisher = NotificationCenter.default.publisher(for: .userDidReceiveRemoteNotification)

    var body: some View {
        switch guardianStates {
        case .idle:
            ProgressView()
                .onAppear(perform: reload)
        case .loading:
            ProgressView()
        case .success(let guardianStates):
            if let guardianState = guardianStates.forParticipantId(participantId) {
                if showGetLive {
                    GetLiveWithOwner(
                        onContinue: {
                            showGetLive = false
                        }
                    )
                } else {
                    switch guardianState.phase {
                    case .recoveryRequested, .recoveryVerification, .recoveryConfirmation:
                        OwnerVerification(
                            session: session,
                            guardianState: guardianState,
                            onGuardianStatesUpdated: replaceGuardianStates,
                            onBack: {
                                showGetLive = true
                            }
                        )
                        .onReceive(refreshStatePublisher) { firedDate in
                            reload()
                        }
                        .onReceive(remoteNotificationPublisher) { _ in
                            reload()
                        }
                    case .complete:
                        OperationCompletedView(successText: "Approval completed")
                            .navigationBarHidden(true)
                            .onAppear {
                                refreshStatePublisher.upstream.connect().cancel()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    onSuccess()
                                }
                            }
                    default:
                        VStack {
                            Text("Invalid Recovery")
                        }
                        .multilineTextAlignment(.center)
                    }
                }
            } else {
                VStack {
                    Text("Invalid Recovery")
                }
                .multilineTextAlignment(.center)
            }
        case .failure(MoyaError.statusCode(let response)) where response.statusCode == 404:
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
}

