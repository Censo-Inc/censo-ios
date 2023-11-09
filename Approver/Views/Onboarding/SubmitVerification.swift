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
    var guardianState: API.GuardianState


    @State private var currentError: Error?
    @State private var verificationCode: [Int] = []
    @State private var disabled = false

    var onSuccess: (API.GuardianState?) -> Void

    private let waitingForVerification = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            Text("Enter the code")
                .font(.title2)
                .bold()
                .padding()
            
            switch guardianState.phase {
            case .waitingForVerification:
                ProgressView(
                    label: {
                        Text("Waiting for the code to be verified...")
                    }
                ).onReceive(waitingForVerification) { _ in
                    reload()
                }
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
        guard let guardianKey = try? session.getOrCreateApproverKey(participantId: guardianState.participantId),
              let (timeMillis, signature) = TotpUtils.signCode(code: code, signingKey: guardianKey),
              let guardianPublicKey = try? guardianKey.publicExternalRepresentation() 
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
                API.SubmitGuardianVerificationApiRequest(
                    signature: signature,
                    timeMillis: timeMillis,
                    guardianPublicKey: guardianPublicKey
                )
            )
        ) { (result: Result<API.SubmitGuardianVerificationApiResponse, MoyaError>) in
            switch result {
            case .success(let response):
                onSuccess(response.guardianState)
            case .failure(let error):
               showError(error)
            }
        }
    }
    
    private func reload() {
        apiProvider.decodableRequest(session.target(for: .user)) {(result: Result<API.GuardianUser, MoyaError>) in
            switch(result) {
            case .success(let user):
                disabled = false
                onSuccess(user.guardianStates.forInvite(invitationId))
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
                       guardianState: .sampleWaitingForCode,
                       onSuccess: {_ in })
}

extension API.GuardianState {
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

extension API.GuardianPhase {
    var isWaitingForVerification: Bool {
        switch self {
        case .waitingForVerification:
            return true
        default:
            return false
        }
    }
}
