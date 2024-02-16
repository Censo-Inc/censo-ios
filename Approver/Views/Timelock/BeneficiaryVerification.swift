//
//  BeneficiaryVerification.swift
//  Approver
//
//  Created by Brendan Flood on 2/14/24.
//

import SwiftUI
import Moya
import BigInt
import Sentry
import Base32

struct BeneficiaryVerification: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss
    
    enum Step {
        case getLive
        case verify
    }

    @State private var step: Step = .getLive
    @State private var inProgress = false
    @State private var showingError = false
    @State private var error: Error?
    @State private var wrongCode = false
    
    var session: Session
    var takeoverId: TakeoverId
    var approverState: API.ApproverState
    var onApproverStatesUpdated: ([API.ApproverState]) -> Void
    
    var body: some View {
        switch (step) {
        case .getLive:
            GetLiveWithBeneficiary(
                onContinue: {
                    step = .verify
                }
            )
        case .verify:
            VStack(alignment: .center, spacing: 30) {
                Text("Read code")
                    .font(.title2)
                    .bold()
                
                Text("Read aloud this 6-digit code only to the beneficiary. Once they have successfully entered it, their identity will have been verified and the takeover completed.")
                    .font(.subheadline)
                    .padding()
                
                switch (approverState.phase) {
                case .takeoverVerification(let phase):
                    if let totpSecret = try? session.deviceKey.decrypt(data: phase.encryptedTotpSecret.data) {
                        RotatingTotpPinView(
                            totpSecret: totpSecret,
                            style: .approver
                        )
                    } else {
                        Text("Can't decrypt TOTP-secret")
                    }
                case .takeoverConfirmation(let status):
                    if let totpSecret = try? session.deviceKey.decrypt(data: status.encryptedTotpSecret.data) {
                        RotatingTotpPinView(
                            totpSecret: totpSecret,
                            style: .approver
                        )
                        .onAppear {
                            confirmOrRejectTakeover(
                                takeoverId: takeoverId,
                                participantId: approverState.participantId,
                                status: status
                            )
                        }
                    }
                default:
                    EmptyView()
                }
                
                if wrongCode {
                    Text("The code was entered incorrectly")
                        .font(.subheadline)
                        .foregroundColor(Color.red)
                } else {
                    Text("")
                        .font(.subheadline)
                }
            }
            .multilineTextAlignment(.center)
            .navigationInlineTitle("")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    DismissButton(icon: .back) {
                        step = .getLive
                    }
                }
            }
            .errorAlert(isPresented: $showingError, presenting: error) {
                dismiss()
            }
        }
    }
    
    private func showError(_ error: Error) {
        inProgress = false
        self.error = error
        self.showingError = true
    }
    
    private func confirmOrRejectTakeover(takeoverId: TakeoverId, participantId: ParticipantId, status: API.ApproverPhase.TakeoverConfirmation) {
        if (try? verifyBeneficiarySignature(participantId: participantId, status: status)) ?? false {
            do {
                
                // verify the original signature and if we are out of timelock
                guard let approverKey = participantId.privateKey(userIdentifier: session.userCredentials.userIdentifier, entropy: status.entropy.data),
                      let idBytes = takeoverId.data(using: .utf8),
                      let timeMillisData = String(status.approverKeySignatureTimeMillis).data(using: .utf8),
                      let timelockData = String(status.timelockPeriodInMillis).data(using: .utf8),
                      try approverKey.verifySignature(for: idBytes + timeMillisData + timelockData, signature: status.approverKeySignature) else {
                    throw CensoError.failedToVerifySignature
                }
                
                if Date(timeIntervalSince1970: TimeInterval(status.approverKeySignatureTimeMillis + status.timelockPeriodInMillis) / 1000) > Date.now {
                    throw CensoError.withinTimelock
                }
                
                guard let beneficiaryPublicKey = try? EncryptionKey.generateFromPublicExternalRepresentation(base58PublicKey: status.beneficiaryPublicKey),
                      let encryptedKey = try? beneficiaryPublicKey.encrypt(data: approverKey.decrypt(base64EncodedString: status.approverEncryptedKey)) else {
                    throw CensoError.failedToRecoverPrivateKey
                }
                inProgress = true
                wrongCode = false
                apiProvider.decodableRequest(
                    with: session,
                    endpoint: .approveTakeoverTotpVerification(
                        takeoverId,
                        encryptedKey
                    )
                ) { (result: Result<API.OwnerVerificationApiResponse, MoyaError>) in
                    inProgress = false
                    switch result {
                    case .success(let success):
                        onApproverStatesUpdated(success.approverStates)
                    case .failure(MoyaError.underlying(CensoError.resourceNotFound, nil)):
                        showError(CensoError.accessRequestNotFound)
                    case .failure(let error):
                        showError(error)
                    }
                }
            } catch {
                inProgress = false
                SentrySDK.captureWithTag(error: error, tagValue: "Beneficiary Verification")
                showError(error)
                return
            }
        } else {
            inProgress = true
            apiProvider.decodableRequest(
                with: session,
                endpoint: .rejectTakeoverTotpVerification(takeoverId)
            ) { (result: Result<API.OwnerVerificationApiResponse, MoyaError>) in
                inProgress = false
                    switch result {
                    case .success(let success):
                        wrongCode = true
                        onApproverStatesUpdated(success.approverStates)
                    case .failure(MoyaError.underlying(CensoError.resourceNotFound, nil)):
                        showError(CensoError.accessRequestNotFound)
                    case .failure(let error):
                        showError(error)
                    }
                }
        }
    }
    
    private func verifyBeneficiarySignature(participantId: ParticipantId, status: API.ApproverPhase.TakeoverConfirmation) throws -> Bool {
        guard let totpSecret = try? session.deviceKey.decrypt(data: status.encryptedTotpSecret.data),
              let timeMillisBytes = String(status.beneficiaryKeySignatureTimeMillis).data(using: .utf8),
              let publicKey = try? EncryptionKey.generateFromPublicExternalRepresentation(base58PublicKey: status.beneficiaryPublicKey) else {
            return false
        }
        
        let acceptedDate = Date(timeIntervalSince1970: Double(status.beneficiaryKeySignatureTimeMillis) / 1000.0)
        for date in [acceptedDate, acceptedDate - TotpUtils.period, acceptedDate + TotpUtils.period] {
            if let codeBytes = TotpUtils.getOTP(date: date, secret: totpSecret).data(using: .utf8) {
                if try publicKey.verifySignature(for: codeBytes + timeMillisBytes, signature: status.beneficiaryKeySignature) {
                    return true
                }
            }
        }
        
        return false
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        let session = Session.sample
        BeneficiaryVerification(
            session: session,
            takeoverId: "guid",
            approverState: .init(
                participantId: .random(),
                phase: .takeoverVerification(
                    .init(
                        createdAt: Date(),
                        encryptedTotpSecret: try! session.deviceKey.encrypt(
                            data: base32DecodeToData(generateBase32())!
                        )
                    )
                )
            ),
            onApproverStatesUpdated: { _ in }
        ).foregroundColor(.Censo.primaryForeground)
    }
}
#endif
