//
//  OwnerVerification.swift
//  Access
//
//  Created by Brendan Flood on 9/29/23.
//

import SwiftUI

import SwiftUI
import Moya
import BigInt
import Sentry
import Base32

struct OwnerVerification: View {
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
    
    enum Intent {
        case accessApproval(AccessApprovalId)
        case authResetApproval(AuthenticationResetApprovalId)
    }
    
    var session: Session
    var intent: Intent
    var approverState: API.ApproverState
    var onApproverStatesUpdated: ([API.ApproverState]) -> Void
    
    var body: some View {
        switch (step) {
        case .getLive:
            GetLiveWithOwner(
                intent: .accessApproval,
                onContinue: {
                    step = .verify
                }
            )
        case .verify:
            VStack(alignment: .center, spacing: 30) {
                switch (intent) {
                case .accessApproval(let approvalId):
                    Text("Read code")
                        .font(.title2)
                        .bold()
                    
                    Text("Read aloud this 6-digit code only to the person you are assisting. Once they have successfully entered it, their identity will have been verified and the request approved.")
                        .font(.subheadline)
                        .padding()
                    
                    switch (approverState.phase) {
                    case .accessVerification(let phase):
                        if let totpSecret = try? session.deviceKey.decrypt(data: phase.encryptedTotpSecret.data) {
                            RotatingTotpPinView(
                                totpSecret: totpSecret,
                                style: .approver
                            )
                        } else {
                            Text("Can't decrypt TOTP-secret")
                        }
                    case .accessConfirmation(let status):
                        if let totpSecret = try? session.deviceKey.decrypt(data: status.encryptedTotpSecret.data) {
                            RotatingTotpPinView(
                                totpSecret: totpSecret,
                                style: .approver
                            )
                            .onAppear {
                                confirmOrRejectAccess(
                                    approvalId: approvalId,
                                    participantId: approverState.participantId,
                                    status: status,
                                    entropy: approverState.phase.entropy?.data
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
                case .authResetApproval(let approvalId):
                    SubmitVerification(
                        intent: .authResetApproval(approverState.participantId, approvalId),
                        session: session,
                        approverState: approverState,
                        onSuccess: onApproverStatesUpdated
                    )
                }
            }
            .multilineTextAlignment(.center)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        step = .getLive
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
            }
            .alert("Error", isPresented: $showingError, presenting: error) { _ in
                Button { 
                    dismiss()
                } label: { Text("OK") }
            } message: { error in
                Text(error.localizedDescription)
            }
        }
    }
    
    private func showError(_ error: Error) {
        inProgress = false
        self.error = error
        self.showingError = true
    }
    
    private func confirmOrRejectAccess(approvalId: AccessApprovalId, participantId: ParticipantId, status: API.ApproverPhase.AccessConfirmation, entropy: Data?) {
        if (try? verifyOwnerSignature(participantId: participantId, status: status)) ?? false {
            guard let entropy else {
                SentrySDK.captureWithTag(error: CensoError.invalidEntropy, tagValue: "Verification")
                showError(CensoError.failedToRecoverPrivateKey)
                return
            }
            guard let approverPrivateKey = participantId.privateKey(userIdentifier: session.userCredentials.userIdentifier, entropy: entropy),
                  let approverPublicKey = try? approverPrivateKey.publicExternalRepresentation(),
                  approverPublicKey == status.accessPublicKey else {
                SentrySDK.captureWithTag(error: CensoError.failedToRecoverPrivateKey, tagValue: "Verification")
                showError(CensoError.failedToRecoverPrivateKey)
                return
            }
            guard let ownerPublicKey = try? EncryptionKey.generateFromPublicExternalRepresentation(base58PublicKey: status.ownerPublicKey),
                  let encryptedShard = try? ownerPublicKey.encrypt(data: approverPrivateKey.decrypt(base64EncodedString: status.approverEncryptedShard)) else {
                SentrySDK.captureWithTag(error: CensoError.failedToRecoverShard, tagValue: "Verification")
                showError(CensoError.failedToRecoverShard)
                return
            }
            inProgress = true
            wrongCode = false
            apiProvider.decodableRequest(
                with: session,
                endpoint: .approveAccessVerification(
                    approvalId,
                    encryptedShard
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
        } else {
            inProgress = true
            apiProvider.decodableRequest(
                with: session,
                endpoint: .rejectAccessVerification(approvalId)
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
    
    private func verifyOwnerSignature(participantId: ParticipantId, status: API.ApproverPhase.AccessConfirmation) throws -> Bool {
        guard let totpSecret = try? session.deviceKey.decrypt(data: status.encryptedTotpSecret.data),
              let timeMillisBytes = String(status.ownerKeySignatureTimeMillis).data(using: .utf8),
              let publicKey = try? EncryptionKey.generateFromPublicExternalRepresentation(base58PublicKey: status.ownerPublicKey) else {
            return false
        }
        
        let acceptedDate = Date(timeIntervalSince1970: Double(status.ownerKeySignatureTimeMillis) / 1000.0)
        for date in [acceptedDate, acceptedDate - TotpUtils.period, acceptedDate + TotpUtils.period] {
            if let codeBytes = TotpUtils.getOTP(date: date, secret: totpSecret).data(using: .utf8) {
                if try publicKey.verifySignature(for: codeBytes + timeMillisBytes, signature: status.ownerKeySignature) {
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
        OwnerVerification(
            session: session,
            intent: .accessApproval(""),
            approverState: .init(
                participantId: .random(),
                phase: .accessVerification(
                    .init(
                        createdAt: Date(),
                        accessPublicKey: .sample,
                        encryptedTotpSecret: try! session.deviceKey.encrypt(
                            data: base32DecodeToData(generateBase32())!
                        )
                    )
                )
            ),
            onApproverStatesUpdated: { _ in }
        )
    }
}
#endif
