//
//  AttestKeyVerification.swift
//  Censo
//
//  Created by Ata Namvari on 2023-11-16.
//

import SwiftUI
import CryptoKit
import DeviceCheck
import Moya

struct AttestKeyVerification: View {
    @Environment(\.apiProvider) var apiProvider

    @State private var verificationStatus: VerificationStatus = .idle

    enum VerificationStatus {
        case idle
        case verifying
        case failed(Error)
        case verified
    }

    var session: Session
    var keyId: String
    var onSuccess: () -> Void
    var onKeyError: () -> Void

    var body: some View {
        switch verificationStatus {
        case .idle:
            ProgressView()
                .onAppear(perform: verify)
        case .verifying:
            ProgressView()
        case .failed(let error as DCError) where error.code != DCError.serverUnavailable:
            ProgressView()
                .onAppear(perform: onKeyError)
        case .failed(let error):
            RetryView(error: error, action: verify)
        case .verified:
            ProgressView()
                .onAppear(perform: onSuccess)
        }
    }

    private func verify() {
        verificationStatus = .verifying

        _Concurrency.Task {
            do {
                let attestationChallenge: API.AttestationChallenge = try await apiProvider.decodableRequest(session.target(for: .attestationChallenge))
                let hash = Data(SHA256.hash(data: attestationChallenge.challenge.data))
                let attestation = try await DCAppAttestService.shared.attestKey(keyId, clientDataHash: hash)
                let attestationString = attestation.base64EncodedString()
                let response = try await apiProvider.request(session.target(for: .registerAttestationObject(challenge: attestationChallenge.challenge.value, attestation: attestationString, keyId: keyId)))

                await MainActor.run {
                    if response.statusCode < 400 {
                        self.verificationStatus = .verified
                    } else {
                        self.verificationStatus = .failed(MoyaError.statusCode(response))
                    }
                }
            } catch {
                await MainActor.run {
                    self.verificationStatus = .failed(error)
                }
            }
        }
    }
}
