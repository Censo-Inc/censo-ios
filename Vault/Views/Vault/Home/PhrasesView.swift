//
//  PhrasesView.swift
//  Vault
//
//  Created by Brendan Flood on 10/23/23.
//

import SwiftUI
import Moya

struct PhrasesView: View {
    
    @Environment(\.apiProvider) var apiProvider
    
    
    var session: Session
    var policy: API.Policy
    var vault: API.Vault
    var recovery: API.Recovery?
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    
    @State private var recoveryRequestInProgress = false
    @State private var showingError = false
    @State private var error: Error?
    
    var body: some View {
        VStack {
            VStack {
                if recovery == nil {
                    if (recoveryRequestInProgress) {
                        VStack {
                            ProgressView("Requesting access to seed phrases...")
                                .foregroundColor(.white)
                                .tint(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: .infinity)
                        .background(Color.white)
                    } else {
                        VStack {
                            Spacer()
                            Button {
                                requestRecovery()
                            } label: {
                                HStack {
                                    Spacer()
                                    Image(systemName: "key")
                                        .frame(width: 36, height: 36)
                                    Text("Access phrases")
                                        .font(.system(size: 24, weight: .semibold))
                                        .padding()
                                    Spacer()
                                }
                            }
                            .buttonStyle(RoundedButtonStyle())
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                        .padding()
                        .alert("Error", isPresented: $showingError, presenting: error) { _ in
                            Button {
                                showingError = false
                                error = nil
                            } label: { Text("OK") }
                        } message: { error in
                            Text(error.localizedDescription)
                        }
                    }
                } else {
                    RecoveryView(
                        session: session,
                        threshold: policy.threshold,
                        guardians: policy.guardians,
                        encryptedSecrets: vault.secrets,
                        encryptedMasterKey: policy.encryptedMasterKey,
                        recovery: recovery!,
                        onOwnerStateUpdated: onOwnerStateUpdated
                    )
                }
            }
            Divider()
            .padding([.bottom], 4)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }
    
    func requestRecovery() {
        recoveryRequestInProgress = true
        apiProvider.decodableRequest(
            with: session,
            endpoint: .requestRecovery(API.RequestRecoveryApiRequest(vaultSecretIds: vault.secrets.map({ $0.guid })))
        ) { (result: Result<API.RequestRecoveryApiResponse, MoyaError>) in
            switch result {
            case .success(let response):
                onOwnerStateUpdated(response.ownerState)
            case .failure(let error):
                self.showingError = true
                self.error = error
            }
            self.recoveryRequestInProgress = false
        }
    }
}

#if DEBUG
#Preview {
    PhrasesView(
        session: .sample,
        policy: .sample,
        vault: .sample,
        recovery: nil,
        onOwnerStateUpdated: { _ in }
    )
}
#endif
