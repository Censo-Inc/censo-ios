//
//  SubmitVerification.swift
//  Approver
//
//  Created by Ben Holzman on 9/27/23.
//

import SwiftUI
import Moya
import raygun4apple

struct SubmitVerification: View {
    @Environment(\.apiProvider) var apiProvider
    
    var invitationId: InvitationId
    var session: Session
    var approverState: API.ApproverState


    @State private var currentError: Error?
    @State private var verificationCode: [Int] = []
    @State private var disabled = false

    var onSuccess: (API.ApproverState?) -> Void

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
                .modifier(RefreshOnTimer(timer: $waitingForVerification, interval: 3, refresh: reload))
            case .waitingForCode:
                Text("The person you are assisting will give you a 6-digit code. Enter it below.")
                    .font(.headline)
                    .fontWeight(.medium)
                    .padding(20)
                
            case .verificationRejected:
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
    }
    
    private func submitVerificaton(code: String) {
        guard let approverKey = try? session.getOrCreateApproverKey(participantId: approverState.participantId),
              let (timeMillis, signature) = TotpUtils.signCode(code: code, signingKey: approverKey),
              let approverPublicKey = try? approverKey.publicExternalRepresentation()
        else {
            RaygunClient.sharedInstance().send(error: CensoError.failedToCreateSignature, tags: ["Verification"], customData: nil)
            showError(CensoError.failedToCreateSignature)
            return
        }
        
        currentError = nil
        disabled = true

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
                onSuccess(response.approverState)
            case .failure(MoyaError.underlying(CensoError.resourceNotFound, nil)):
                showError(CensoError.invitationNotFound)
            case .failure(let error):
               showError(error)
            }
        }
    }
    
    private func reload() {
        apiProvider.decodableRequest(session.target(for: .user)) {(result: Result<API.ApproverUser, MoyaError>) in
            switch(result) {
            case .success(let user):
                disabled = false
                onSuccess(user.approverStates.forInvite(invitationId))
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
    SubmitVerification(invitationId: "invitation_01hbbyesezf0kb5hr8v7f2353g", session: .sample,
                       approverState: .sampleWaitingForCode,
                       onSuccess: {_ in })
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
            phase: .verificationRejected,
            invitationId: "invitation_01hbbyesezf0kb5hr8v7f2353g"
        )
    }
    
    static var sampleWaitingForCode: Self {
        .init(
            participantId: .random(),
            phase: .waitingForCode,
            invitationId: "invitation_01hbbyesezf0kb5hr8v7f2353g"
        )
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
