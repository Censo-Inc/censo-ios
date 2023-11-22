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
import raygun4apple
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
    
    var session: Session
    var guardianState: API.GuardianState
    var onGuardianStatesUpdated: ([API.GuardianState]) -> Void
    
    var body: some View {
        switch (step) {
        case .getLive:
            GetLiveWithOwner(
                onContinue: {
                    step = .verify
                }
            )
        case .verify:
            VStack(alignment: .center, spacing: 30) {
                Text("Read code")
                    .font(.title2)
                    .bold()
                
                Text("Read aloud this 6-digit code only to the person you are assisting. Once they have successfully entered it, their identity will have been verified and the request approved.")
                    .font(.subheadline)
                    .padding()

                switch (guardianState.phase) {
                case .recoveryVerification(let phase):
                    RotatingTotpPinView(
                        session: session,
                        deviceEncryptedTotpSecret: phase.encryptedTotpSecret,
                        style: .approver
                    )
                case .recoveryConfirmation(let status):
                    RotatingTotpPinView(
                        session: session,
                        deviceEncryptedTotpSecret: status.encryptedTotpSecret,
                        style: .approver
                    )
                    .onAppear {
                        confirmOrRejectOwner(
                            participantId: guardianState.participantId,
                            status: status
                        )
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
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        step = .getLive
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
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
    
    private func confirmOrRejectOwner(participantId: ParticipantId, status: API.GuardianPhase.RecoveryConfirmation) {
        if (try? verifyOwnerSignature(participantId: participantId, status: status)) ?? false {
            guard let guardianPrivateKey = participantId.privateKey(userIdentifier: session.userCredentials.userIdentifier),
                  let guardianPublicKey = try? guardianPrivateKey.publicExternalRepresentation(),
                  guardianPublicKey == status.recoveryPublicKey else {
                RaygunClient.sharedInstance().send(error: CensoError.failedToRecoverPrivateKey, tags: ["Verification"], customData: nil)
                showError(CensoError.failedToRecoverPrivateKey)
                return
            }
            guard let ownerPublicKey = try? EncryptionKey.generateFromPublicExternalRepresentation(base58PublicKey: status.ownerPublicKey),
                  let encryptedShard = try? ownerPublicKey.encrypt(data: guardianPrivateKey.decrypt(base64EncodedString: status.guardianEncryptedShard)) else {
                RaygunClient.sharedInstance().send(error: CensoError.failedToRecoverShard, tags: ["Verification"], customData: nil)
                showError(CensoError.failedToRecoverShard)
                return
            }
            inProgress = true
            wrongCode = false
            apiProvider.decodableRequest(
                with: session,
                endpoint: .approveOwnerVerification(
                    participantId,
                    encryptedShard
                )
            ) { (result: Result<API.OwnerVerificationApiResponse, MoyaError>) in
                inProgress = false
                switch result {
                case .success(let success):
                    onGuardianStatesUpdated(success.guardianStates)
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
                endpoint: .rejectOwnerVerification(participantId)
            ) { (result: Result<API.OwnerVerificationApiResponse, MoyaError>) in
                inProgress = false
                    switch result {
                    case .success(let success):
                        wrongCode = true
                        onGuardianStatesUpdated(success.guardianStates)
                    case .failure(MoyaError.underlying(CensoError.resourceNotFound, nil)):
                        showError(CensoError.accessRequestNotFound)
                    case .failure(let error):
                        showError(error)
                    }
                }
        }
    }
    
    private func verifyOwnerSignature(participantId: ParticipantId, status: API.GuardianPhase.RecoveryConfirmation) throws -> Bool {
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
            guardianState: .init(
                participantId: .random(),
                phase: .recoveryVerification(
                    .init(
                        createdAt: Date(),
                        recoveryPublicKey: .sample,
                        encryptedTotpSecret: try! session.deviceKey.encrypt(
                            data: base32DecodeToData(generateBase32())!
                        )
                    )
                )
            ),
            onGuardianStatesUpdated: { _ in }
        )
    }
}
#endif
