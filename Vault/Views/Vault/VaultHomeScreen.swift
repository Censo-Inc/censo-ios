//
//  VaultHomeScreen.swift
//  Vault
//
//  Created by Anton Onyshchenko on 29.09.23.
//

import Foundation
import SwiftUI
import Moya

struct VaultHomeScreen: View {
    @Environment(\.apiProvider) var apiProvider
    
    var session: Session
    var policy: API.Policy
    var vault: API.Vault
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    
    @State private var recoveryRequestInProgress = false
    @State private var showingError = false
    @State private var error: Error?
    
    var body: some View {
        if (recoveryRequestInProgress) {
            VStack {
                ProgressView("Requesting recovery")
                    .foregroundColor(.white)
                    .tint(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
            .background(Color.Censo.darkBlue)
        } else {
            if (policy.recovery == nil) {
                NavigationStack {
                    VStack {
                        Spacer()
                        
                        Text("Your seed phrases are protected")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Spacer()
                        
                        NavigationLink {
                            SecretsListView(
                                session: session,
                                vault: vault,
                                onOwnerStateUpdated: onOwnerStateUpdated
                            )
                        } label: {
                            Text("Edit Seed Phrases")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .frame(height: 44)
                        }
                        .padding()
                        .buttonStyle(BorderedButtonStyle(tint: .light))
                        
                        VStack {
                            Button {
                                requestRecovery()
                            } label: {
                                Text("Recover Phrases")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .frame(height: 44)
                            }
                            .buttonStyle(FilledButtonStyle(tint: .light))
                        }.padding()
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                    .background(Color.Censo.darkBlue)
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
                    recovery: policy.recovery!,
                    onOwnerStateUpdated: onOwnerStateUpdated
                )
            }
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
extension API.Policy {
    static var sample: Self {
        .init(
            createdAt: Date(),
            guardians: [],
            threshold: 2,
            encryptedMasterKey: Base64EncodedString(data: Data()),
            intermediateKey: try! Base58EncodedPublicKey(value: "PQVchxggKG9sQRNx9Yi6Yu5gSCeLQFmxuCzmx1zmNBdRVoCTPeab1F612GE4N7UZezqGBDYUB25yGuFzWsob9wY2"),
            recovery: nil
        )
    }
}

extension API.Vault {
    static var sample: Self {
        .init(
            secrets: [],
            publicMasterEncryptionKey: try! Base58EncodedPublicKey(value: "PQVchxggKG9sQRNx9Yi6Yu5gSCeLQFmxuCzmx1zmNBdRVoCTPeab1F612GE4N7UZezqGBDYUB25yGuFzWsob9wY2")
        )
    }
}

struct VaultHomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        LockedScreen(
            Session.sample,
            600,
            onOwnerStateUpdated: { _ in },
            onUnlockedTimeOut: {}
        ) {
            VaultHomeScreen(
                session: .sample,
                policy: .sample,
                vault: .sample,
                onOwnerStateUpdated: { _ in }
            )
        }
    }
}
#endif
