//
//  SubmitVerification.swift
//  Approver
//
//  Created by Ben Holzman on 9/27/23.
//

import SwiftUI
import Moya
import Sentry

struct SubmitVerification: View {
    @Environment(\.apiProvider) var apiProvider
    
    enum Intent {
        case onboarding(InvitationId)
        case authResetApproval(ParticipantId, AuthenticationResetApprovalId)
    }
    
    var intent: Intent
    var session: Session
    var approverState: API.ApproverState

    @State private var currentError: Error?
    @State private var verificationCode: [Int] = []
    @State private var disabled = false

    var onSuccess: ([API.ApproverState]) -> Void

    @State private var waitingForVerification = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            Text("Enter the code")
                .font(.title2)
                .bold()
                .padding()
            
            switch approverState.phase {
            case .waitingForVerification:
                ProgressView(
                    label: {
                        Text("Waiting for the code to be verified...")
                    }
                )
            case .waitingForCode, .authenticationResetWaitingForCode:
                Text("The person you are assisting will give you a 6-digit code. Enter it below.")
                    .font(.headline)
                    .fontWeight(.medium)
                    .padding(20)
                
            case .verificationRejected, .authenticationResetVerificationRejected:
                Text("That code was not verified. Please get another code and try again.")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(Color.red)
                    .padding()
                
            default:
                EmptyView()
            }
            
            VStack {
                VerificationCodeEntry(
                    pinInput: $verificationCode, 
                    disabled: self.disabled
                )
                .onChange(of: verificationCode) { _ in
                    if (verificationCode.count == 6) {
                        submitVerificaton(code: verificationCode.map({ digit in String(digit) }).joined())
                    }
                }
            }

            if (currentError != nil) {
                Text(currentError!.localizedDescription)
                    .bold()
                    .foregroundColor(Color.red)
                    .multilineTextAlignment(.center)
            }
        }
        .multilineTextAlignment(.center)
        .modifier(RefreshOnTimer(timer: $waitingForVerification, refresh: reload, isIdleTimerDisabled: true))
    }
    
    private func submitVerificaton(code: String) {
        guard let entropy = approverState.phase.entropy,
              let approverKey = try? session.getOrCreateApproverKey(participantId: approverState.participantId, entropy: entropy.data),
              let (timeMillis, signature) = TotpUtils.signCode(code: code, signingKey: approverKey),
              let approverPublicKey = try? approverKey.publicExternalRepresentation()
        else {
            SentrySDK.captureWithTag(error: CensoError.failedToCreateSignature, tagValue: "Verification")
            showError(CensoError.failedToCreateSignature)
            return
        }
        
        currentError = nil
        disabled = true

        switch (intent) {
        case .onboarding(let invitationId):
            apiProvider.decodableRequest(
                with: session,
                endpoint: .submitVerification(
                    invitationId,
                    API.SubmitApproverVerificationApiRequest(
                        signature: signature,
                        timeMillis: timeMillis,
                        approverPublicKey: approverPublicKey
                    )
                )
            ) { (result: Result<API.SubmitApproverVerificationApiResponse, MoyaError>) in
                switch result {
                case .success(let response):
                    onSuccess([response.approverState])
                case .failure(MoyaError.underlying(CensoError.resourceNotFound, nil)):
                    showError(CensoError.invitationNotFound)
                case .failure(let error):
                    showError(error)
                }
            }
        case .authResetApproval(_, let approvalId):
            apiProvider.decodableRequest(
                with: session,
                endpoint: .submitAuthenticationResetTotpVerification(
                    approvalId,
                    API.SubmitAuthenticationResetTotpVerificationApiRequest(
                        signature: signature,
                        timeMillis: timeMillis
                    )
                )
            ) { (result: Result<API.SubmitAuthenticationResetTotpVerificationApiResponse, MoyaError>) in
                switch result {
                case .success(let response):
                    onSuccess(response.approverStates)
                case .failure(MoyaError.underlying(CensoError.resourceNotFound, nil)):
                    showError(CensoError.invitationNotFound)
                case .failure(let error):
                    showError(error)
                }
            }
        }
    }
    
    private func reload() {
        apiProvider.decodableRequest(session.target(for: .user)) {(result: Result<API.ApproverUser, MoyaError>) in
            switch(result) {
            case .success(let user):
                disabled = false
                switch (intent) {
                case .onboarding:
                    onSuccess(user.approverStates)
                case .authResetApproval:
                    onSuccess(user.approverStates)
                }
            case .failure:
                break
            }
        }
    }

    private func showError(_ error: Error) {       
        currentError = error
        disabled = false
    }
}

#if DEBUG
#Preview {
    SubmitVerification(
        intent: .onboarding("invitation_01hbbyesezf0kb5hr8v7f2353g"),
        session: .sample,
        approverState: .sampleWaitingForCode,
        onSuccess: {_ in }
    )
}

extension API.ApproverState {
    static var sampleWaitingForVerification: Self {
        .init(
            participantId: .random(),
            phase: .waitingForVerification,
            invitationId: "invitation_01hbbyesezf0kb5hr8v7f2353g"
        )
    }
    
    static var sampleVerificationRejected: Self {
        .init(
            participantId: .random(),
            phase: .verificationRejected(.sample),
            invitationId: "invitation_01hbbyesezf0kb5hr8v7f2353g"
        )
    }
    
    static var sampleWaitingForCode: Self {
        .init(
            participantId: .random(),
            phase: .waitingForCode(.sample),
            invitationId: "invitation_01hbbyesezf0kb5hr8v7f2353g"
        )
    }
}

extension API.ApproverPhase.VerificationRejected {
    static var sample: Self {
        .init(entropy: Base64EncodedString(data: Data()))
    }
}

extension API.ApproverPhase.WaitingForCode {
    static var sample: Self {
        .init(entropy: Base64EncodedString(data: Data()))
    }
}
#endif

extension API.ApproverPhase {
    var isWaitingForVerification: Bool {
        switch self {
        case .waitingForVerification:
            return true
        default:
            return false
        }
    }
}
