//
//  AttestKeyGeneration.swift
//  Censo
//
//  Created by Ata Namvari on 2023-11-16.
//

import SwiftUI
import DeviceCheck

enum AttestationError: Error {
    case notSupported
}

struct AttestKeyGeneration: View {
    @State private var attest: Result<String, Error>?

    var onSuccess: (AttestKey) -> Void

    var body: some View {
        switch attest {
        case .success(let keyId):
            ProgressView()
                .onAppear {
                    onSuccess(AttestKey(keyId: keyId))
                }
        case .failure(let error):
            RetryView(error: error, action: generateKey)
        case nil:
            ProgressView()
                .onAppear(perform: generateKey)
        }
    }

    private func generateKey() {
        let service = DCAppAttestService.shared

        guard service.isSupported else {
            self.attest = .failure(AttestationError.notSupported)
            return
        }

        _Concurrency.Task {
            do {
                let keyId = try await service.generateKey()
                await MainActor.run {
                    self.attest = .success(keyId)
                }
            } catch {
                await MainActor.run {
                    self.attest = .failure(error)
                }
            }
        }
    }
}
