//
//  TakeoverInitiation.swift
//  Approver
//
//  Created by Brendan Flood on 2/12/24.
//

import SwiftUI
import Moya
import Sentry

enum TakeoverAction {
    case none
    case approved
    case declined
    
    func name() -> String {
        switch self {
        case .approved: return "approved"
        case .declined: return "declined"
        case .none: return "none"
        }
    }
}

struct TakeoverInitiation: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss
    
    var session: Session
    var participantId: ParticipantId
    var takeoverId: String
    var onSuccess: () -> Void

    @RemoteResult<[API.ApproverState], API> private var approverStates
    @State private var inProgress = false
    @State private var showingError = false
    @State private var error: Error?
    @State private var action: TakeoverAction = .none
    @State private var timelockPeriodInMillis: UInt64?

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
                case .takeoverRequested(let takeoverRequested):
                    TakeoverInitiationApproveOrReject(
                        onApprove: {
                            timelockPeriodInMillis = takeoverRequested.timelockPeriodInMillis
                            approveTakeover(
                                entropy: takeoverRequested.entropy,
                                timelockPeriodInMillis: takeoverRequested.timelockPeriodInMillis
                            )
                        },
                        onReject: {
                            rejectTakeover()
                        },
                        inProgress: inProgress
                    )
                    .errorAlert(isPresented: $showingError, presenting: error)
                case .complete where action == .approved:
                    TakeoverInitiationDone(action: action, onOk: onSuccess, timelockPeriodInMillis: self.timelockPeriodInMillis)
                    
                case .complete where action == .declined:
                    TakeoverInitiationDone(action: action, onOk: onSuccess)
                    
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
        inProgress = false
        showingError = true
        self.error = error
    }
    
    private func approveTakeover(entropy: Base64EncodedString, timelockPeriodInMillis: UInt64) {
        inProgress = true
        let timeMillis = UInt64(Date().timeIntervalSince1970 * 1000)
        guard let approverKey = try? session.getOrCreateApproverKey(keyId: participantId, entropy: entropy.data),
              let idBytes = takeoverId.data(using: .utf8),
              let timeMillisData = String(timeMillis).data(using: .utf8),
              let timelockData = String(timelockPeriodInMillis).data(using: .utf8),
              let signature = try? approverKey.signature(for: idBytes + timeMillisData + timelockData)
        else {
            SentrySDK.captureWithTag(error: CensoError.failedToCreateSignature, tagValue: "Verification")
            showError(CensoError.failedToCreateSignature)
            return
        }
    
        
        apiProvider.decodableRequest(
            with: session,
            endpoint: .approveTakeoverInitiation(
                takeoverId,
                API.ApproveTakeoverInitiationApiRequest(
                    signature: signature,
                    timeMillis: timeMillis
                )
            )
        ) { (result: Result<API.OwnerVerificationApiResponse, MoyaError>) in
            inProgress = false
            switch result {
            case .success(let success):
                action = .approved
                replaceApproverStates(newApproverStates: success.approverStates)
            case .failure(MoyaError.underlying(CensoError.resourceNotFound, nil)):
                showError(CensoError.accessRequestNotFound)
            case .failure(let error):
                showError(error)
            }
        }
    }
    
    private func rejectTakeover() {
        inProgress = true
        apiProvider.decodableRequest(
            with: session,
            endpoint: .rejectTakeoverInitiation(
                takeoverId
            )
        ) { (result: Result<API.OwnerVerificationApiResponse, MoyaError>) in
            inProgress = false
            switch result {
            case .success(let success):
                action = .declined
                replaceApproverStates(newApproverStates: success.approverStates)
            case .failure(MoyaError.underlying(CensoError.resourceNotFound, nil)):
                showError(CensoError.accessRequestNotFound)
            case .failure(let error):
                showError(error)
            }
        }
    }
}

struct TakeoverInitiationApproveOrReject: View {
    var onApprove: () -> Void
    var onReject: () -> Void
    var inProgress: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            Spacer()
            
            Text("Approve takeover initiation")
                .font(.title3)
                .bold()
                .padding(.vertical)
            
            Text("""
                The beneficiary of the person you have been assisting has requested to initiate a takeover.

                If you have verified the identity of the beneficiary, and the authenticity of their request, tap the Approve button. Following the timelock period, you will need to assist the beneficiary again to complete the takeover.

                If you do not believe this is an authentic request, tap the Decline button and notify the person you have been assisting immediately.
                """)
            .font(.subheadline)
            .padding(.bottom)
            
            Button {
                onApprove()
            } label: {
                Text("Approve")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            .disabled(inProgress)
            
            Button {
                onReject()
            } label: {
                Text("Decline")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            .disabled(inProgress)
        }
        .padding(.vertical)
        .padding(.horizontal, 32)
    }
}

struct TakeoverInitiationDone: View {
    
    var action: TakeoverAction = .none
    var onOk: () -> Void
    var timelockPeriodInMillis: UInt64?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            Spacer()
            
            Text("Takeover initiation \(action.name())")
                .font(.title3)
                .bold()
                .padding(.vertical)
            
            if action == .approved {
                Text("""
                The takeover initiation request from the beneficiary of the person you have been assisting is now approved.
                
                In \(timelockPeriodInMillis?.millisToDisplayDuration() ?? "7 days"), the takeover will be ready to be completed, and the beneficiary should contact you to approve completing the takeover.
                """)
                .font(.subheadline)
            } else {
                Text("""
                    You have declined the takeover initiation request from the beneficiary of the person you have been assisting.

                    You should notify the person you have been assisting immediately.
                    """)
                .font(.subheadline)
            }
            
            Spacer()
            
            Button {
                onOk()
            } label: {
                Text("Ok")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
        }
        .padding(.horizontal, 32)
        .padding(.vertical)
        .navigationBarBackButtonHidden()
    }
}

#if DEBUG
#Preview("Takeover initiation") {
    TakeoverInitiationApproveOrReject(onApprove: {}, onReject: {})
        .foregroundColor(.Censo.primaryForeground)
}

#Preview("Takeover approved") {
    TakeoverInitiationDone(action: .approved, onOk: {})
        .foregroundColor(.Censo.primaryForeground)
}

#Preview("Takeover declined") {
    TakeoverInitiationDone(action: .declined, onOk: {})
        .foregroundColor(.Censo.primaryForeground)
}
#endif
