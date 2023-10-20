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
    var recovery: API.Recovery?
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    
    @State private var recoveryRequestInProgress = false
    @State private var showingError = false
    @State private var error: Error?
    @State private var resetRequested = false
    @State private var resetInProgress = false
    
    var body: some View {
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
            if (recovery == nil) {
                NavigationStack {
                    VStack {
                        Spacer()
                        
                        Text("Your seed phrases are protected")
                            .font(.title2)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Spacer()
                        
                        NavigationLink {
                            SecretsListView(
                                session: session,
                                vault: vault,
                                onOwnerStateUpdated: onOwnerStateUpdated
                            )
                        } label: {
                            HStack {
                                Spacer()
                                Image("PhraseEntry")
                                    .frame(width: 36, height: 36)
                                    .colorInvert()
                                Text("Add seed phrases").padding()
                                Spacer()
                            }
                        }
                        .padding()
                        .buttonStyle(RoundedButtonStyle())
                        .disabled(resetInProgress)
                        
                        VStack {
                            Button {
                                requestRecovery()
                            } label: {
                                HStack {
                                    Spacer()
                                    Image(systemName: "key")
                                        .frame(width: 36, height: 36)
                                    Text("Access phrases").padding()
                                    Spacer()
                                }
                            }
                            .buttonStyle(RoundedButtonStyle())
                            .disabled(resetInProgress)
                        }.padding()
                        
                        
                        if (policy.guardians.count <= 1) {
                            VStack {
                                Button {
                                } label: {
                                    HStack {
                                        Spacer()
                                        Image("TwoPeopleWhite")
                                            .frame(width: 36, height: 36)
                                        Text("Invite approvers").padding()
                                        Spacer()
                                    }
                                }
                                .buttonStyle(RoundedButtonStyle())
                                .disabled(resetInProgress)
                            }.padding()
                        }
                        
                        VStack {
                            Button {
                                resetRequested = true
                            } label: {
                                if resetInProgress {
                                    ProgressView()
                                } else {
                                    HStack {
                                        Spacer()
                                        Image("arrow.circlepath")
                                            .frame(width: 36, height: 36)
                                        Text("Reset User Data").padding()
                                        Spacer()
                                    }
                                }
                            }
                            .buttonStyle(RoundedButtonStyle())
                        }.padding()
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                    .alert("Error", isPresented: $showingError, presenting: error) { _ in
                        Button {
                            showingError = false
                            error = nil
                        } label: { Text("OK") }
                    } message: { error in
                        Text(error.localizedDescription)
                    }
                    .alert("Reset User", isPresented: $resetRequested) {
                        Button {
                            deleteUser()
                        } label: { Text("Confirm") }
                        Button {
                        } label: { Text("Cancel") }
                    } message: {
                        Text("You are about to delete your user and associated data. This action cannot be reversed. \nAre you sure?")
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
    
    private func deleteUser() {
        resetInProgress = true
        apiProvider.request(with: session, endpoint: .deleteUser) { result in
            resetInProgress = false
            switch result {
            case .success:
                onOwnerStateUpdated(.initial)
            case .failure(let error):
                self.showingError = true
                self.error = error
            }
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
            intermediateKey: try! Base58EncodedPublicKey(value: "PQVchxggKG9sQRNx9Yi6Yu5gSCeLQFmxuCzmx1zmNBdRVoCTPeab1F612GE4N7UZezqGBDYUB25yGuFzWsob9wY2")
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
        VaultHomeScreen(
            session: .sample,
            policy: .sample,
            vault: .sample,
            recovery: nil,
            onOwnerStateUpdated: { _ in }
        )
    }
}
#endif
