//
//  SubmitVerification.swift
//  Guardian
//
//  Created by Ben Holzman on 9/27/23.
//

import SwiftUI
import Moya

struct SubmitVerification: View {
    @Environment(\.apiProvider) var apiProvider
    var invitationId: InvitationId
    var session: Session
    var guardianState: API.GuardianState


    @State private var currentError: Error?

    @State private var verificationCode: [Int] = []

    var onSuccess: (API.GuardianState?) -> Void

    let waitingForVerification = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit")
                .font(.title)
                .padding()
            Spacer()
            VStack {
                VerificationCodeEntry(pinInput: $verificationCode)
                    .onChange(of: verificationCode) { _ in
                        if (verificationCode.count == 6) {
                            submitVerificaton(code: verificationCode.map({ digit in String(digit) }).joined())
                        }
                    }
                    .disabled(
                        !guardianState.phase.isWaitingForVerification
                    )

                if (currentError == nil) {
                    switch guardianState.phase {
                    case .waitingForVerification:
                        ProgressView(
                            label: {
                                Text("Waiting for owner to verify the code.")
                            }
                        ).onReceive(waitingForVerification) { firedDate in
                            apiProvider.decodableRequest(session.target(for: .user)) {(result: Result<API.GuardianUser, MoyaError>) in
                                switch(result) {
                                case .success(let user):
                                    onSuccess(user.guardianStates.forInvite(invitationId))
                                case .failure:
                                    break
                                }
                            }
                        }
                        
                    case .verificationRejected:
                        Text(CensoError.verificationFailed.localizedDescription)
                            .bold()
                            .foregroundColor(Color.red)
                            .multilineTextAlignment(.center)
                        
                    default:
                        EmptyView()
                    }
                } else {
                    Text(currentError!.localizedDescription)
                        .bold()
                        .foregroundColor(Color.red)
                        .multilineTextAlignment(.center)
                }
                
            }
                .frame(height: 200, alignment: .topLeading)
            
             Spacer()
        }
    }
    
    private func submitVerificaton(code: String) {
        
        let timeMillis = UInt64(Date().timeIntervalSince1970 * 1000)
        guard let guardianKey = try? guardianState.participantId.generateGuardianKey(),
              let codeBytes = code.data(using: .utf8),
              let timeMillisData = String(timeMillis).data(using: .utf8),
              let guardianPublicKey = try? guardianKey.publicExternalRepresentation(),
              let signature = try? guardianKey.signature(for: codeBytes + timeMillisData) else {
            showError(CensoError.failedToCreateSignature)
            return
        }
        
        currentError = nil

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

    private func showError(_ error: Error) {       
        currentError = error
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
            phase: .waitingForVerification(
                API.GuardianPhase.WaitingForVerification(
                    invitationId: "invitation_01hbbyesezf0kb5hr8v7f2353g"
                )
            )
        )
    }
    
    static var sampleVerificationRejected: Self {
        .init(
            participantId: .random(),
            phase: .verificationRejected(
                API.GuardianPhase.VerificationRejected(
                    invitationId: "invitation_01hbbyesezf0kb5hr8v7f2353g"
                )
            )
        )
    }
    
    static var sampleWaitingForCode: Self {
        .init(
            participantId: .random(),
            phase: .waitingForCode(
                API.GuardianPhase.WaitingForCode(
                    invitationId: "invitation_01hbbyesezf0kb5hr8v7f2353g"
                )
            )
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
