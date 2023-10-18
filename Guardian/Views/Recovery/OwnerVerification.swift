//
//  OwnerVerification.swift
//  Recovery
//
//  Created by Brendan Flood on 9/29/23.
//

import SwiftUI

import SwiftUI
import Moya
import BigInt

struct  OwnerVerification: View {
    @Environment(\.apiProvider) var apiProvider
    
    @State private var inProgress = false
    @State private var showingError = false
    @State private var error: Error?

    var session: Session
    var guardianState: API.GuardianState
    var onSuccess: () -> Void
    
    var body: some View {
        VStack(alignment: .center) {
            
            Text("Tell seed phrase owner this 6-digit code to approve their access")
                .font(.headline)
                .padding()
            
            switch (guardianState.phase) {
            case .recoveryVerification(let phase):
                RotatingTotpPinView(
                    session: session,
                    deviceEncryptedTotpSecret: phase.encryptedTotpSecret
                )
                .frame(width: .infinity, height: 64)
            case .recoveryConfirmation(let status):
                RotatingTotpPinView(
                    session: session,
                    deviceEncryptedTotpSecret: status.encryptedTotpSecret
                )
                .frame(width: .infinity, height: 64)
                .onAppear {
                    confirmOrRejectOwner(
                        participantId: guardianState.participantId,
                        status: status
                    )
                }
            default:
                EmptyView()
            }
        }
        .multilineTextAlignment(.center)
        .alert("Error", isPresented: $showingError, presenting: error) { _ in
            Button { } label: { Text("OK") }
        } message: { error in
            Text(error.localizedDescription)
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
                showError(CensoError.failedToRecoverPrivateKey)
                return
            }
            guard let ownerPublicKey = try? EncryptionKey.generateFromPublicExternalRepresentation(base58PublicKey: status.ownerPublicKey),
                  let encryptedShard = try? ownerPublicKey.encrypt(data: guardianPrivateKey.decrypt(base64EncodedString: status.guardianEncryptedShard)) else {
                showError(CensoError.failedToRecoverShard)
                return
            }
            inProgress = true
            apiProvider.decodableRequest(
                with: session,
                endpoint: .approveOwnerVerification(
                    participantId,
                    encryptedShard
                )
            ) { (result: Result<API.OwnerVerificationApiResponse, MoyaError>) in
                inProgress = false
                switch result {
                case .success:
                    onSuccess()
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
                    case .success:
                        onSuccess()
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
    OwnerVerification(
        session: .sample,
        guardianState: .sampleRecoveryVerification,
        onSuccess: {}
    )
}

extension API.GuardianPhase.RecoveryVerification {
    static var sample: Self {
        .init(createdAt: Date(),
              recoveryPublicKey: .sample,
              encryptedTotpSecret: try! DeviceKey.sample.encrypt(
                data: generateBase32().decodeBase32()
              )
        )
    }
}

extension API.GuardianState {
    static var sampleRecoveryVerification: Self {
        .init(
            participantId: .random(),
            phase: .recoveryVerification(.sample)
        )
    }
}
#endif
