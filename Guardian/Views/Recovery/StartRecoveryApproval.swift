//
//  StartRecovery.swift
//  Recovery
//
//  Created by Brendan Flood on 9/29/23.
//

import SwiftUI

import SwiftUI
import Moya

struct  StartRecoveryApproval: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss
    
    @State private var inProgress = false
    @State private var showingError = false
    @State private var error: Error?

    var session: Session
    var guardianState: API.GuardianState
    var onSuccess: () -> Void
    
    var body: some View {
        VStack {
            
            Text("Seed phrase owner has requested access approval")
                .font(.headline)
                .padding()
            
            
            Button {
                startOwnerVerification(participantId: guardianState.participantId)
            } label: {
                if (inProgress) {
                    ProgressView()
                } else {
                    Text("Continue")
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .frame(height: 44)
                }
            }
            .padding()
            .buttonStyle(RoundedButtonStyle(maxWidth: 160))
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
                case .success:
                    onSuccess()
                case .failure(let error):
                    showError(error)
                }
            }
        } catch {
            showError(error)
        }
    }
}

#if DEBUG
#Preview {
    StartRecoveryApproval(session: .sample, guardianState: .sample, onSuccess: {})
}

extension Base58EncodedPublicKey {
    static var sample: Self {
        try! .init(value: "PQVchxggKG9sQRNx9Yi6Yu5gSCeLQFmxuCzmx1zmNBdRVoCTPeab1F612GE4N7UZezqGBDYUB25yGuFzWsob9wY2")
    }
}
extension API.GuardianPhase.RecoveryRequested {
    static var sample: Self {
        .init(createdAt: Date(), recoveryPublicKey: .sample)
    }
}

extension API.GuardianState {
    static var sample: Self {
        .init(
            participantId: .random(),
            phase: .recoveryRequested(.sample)
        )
    }
}
#endif
