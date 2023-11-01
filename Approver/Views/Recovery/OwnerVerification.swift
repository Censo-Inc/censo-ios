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
import raygun4apple

struct OwnerVerification: View {
    @Environment(\.apiProvider) var apiProvider
    
    @State private var inProgress = false
    @State private var showingError = false
    @State private var error: Error?
    @State private var wrongCode = false

    var session: Session
    var guardianState: API.GuardianState
    var onGuardianStatesUpdated: ([API.GuardianState]) -> Void
    var onBack: () -> Void
    
    var body: some View {
        VStack(alignment: .center, spacing: 30) {
            Text("Share the code")
                .font(.system(size: 24))
                .bold()
            
            Text("The owner must enter this 6-digit code:")
                .font(.system(size: 14))
            
            switch (guardianState.phase) {
            case .recoveryRequested:
                ProgressView()
                    .onAppear {
                        startOwnerVerification(participantId: guardianState.participantId)
                    }
            case .recoveryVerification(let phase):
                RotatingTotpPinView(
                    session: session,
                    deviceEncryptedTotpSecret: phase.encryptedTotpSecret,
                    style: .approver
                )
                .frame(width: .infinity)
            case .recoveryConfirmation(let status):
                RotatingTotpPinView(
                    session: session,
                    deviceEncryptedTotpSecret: status.encryptedTotpSecret,
                    style: .approver
                )
                .frame(width: .infinity)
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
                Text("Owner entered wrong code")
                    .font(.system(size: 14))
                    .foregroundColor(Color.red)
            } else {
                Text("")
                    .font(.system(size: 14))
            }
        }
        .multilineTextAlignment(.center)
        .navigationTitle(Text("Approve Access"))
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    onBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                }
            }
        }
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
    
    private func startOwnerVerification(participantId: ParticipantId) {
        inProgress = true

        do {
            let encryptedTotpSecret = try Base64EncodedString.encryptedTotpSecret(deviceKey: session.deviceKey)

            apiProvider.decodableRequest(
                with: session,
                endpoint: .storeRecoveryTotpSecret(
                    participantId,
                    encryptedTotpSecret
                )
            ) { (result: Result<API.OwnerVerificationApiResponse, MoyaError>) in
                inProgress = false
                switch result {
                case .success(let success):
                    onGuardianStatesUpdated(success.guardianStates)
                case .failure(let error):
                    showError(error)
                }
            }
        } catch {
            showError(error)
        }
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
                            data: generateBase32().decodeBase32()
                        )
                    )
                )
            ),
            onGuardianStatesUpdated: { _ in },
            onBack: {}
        )
    }
}
#endif
