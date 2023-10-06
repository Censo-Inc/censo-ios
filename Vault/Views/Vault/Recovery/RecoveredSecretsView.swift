//
//  RecoveredPhrasesView.swift
//  Vault
//
//  Created by Anton Onyshchenko on 06.10.23.
//

import Foundation
import SwiftUI
import Moya
import BigInt

struct RecoveredSecretsView: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss
    
    var session: Session
    var requestedSecrets: [API.VaultSecret]
    var encryptedMasterKey: Base64EncodedString
    var deleteRecovery: () -> Void
    
    struct RecoveredSecret {
        var label: String
        var secret: String
    }
    
    enum Status {
        case retrievingShards
        case showingSecrets(secrets: [RecoveredSecret])
    }
    
    @State var status: Status = .retrievingShards
    @State var showingError = false
    @State var error: Error?
    
    var body: some View {
        VStack {
            switch (status) {
            case .retrievingShards:
                FacetecAuth<API.RetrieveRecoveryShardsApiResponse>(
                    session: session,
                    onReadyToUploadResults: { biomentryVerificationId, biometryData in
                        return .retrieveRecoveredShards(API.RetrieveRecoveryShardsApiRequest(
                            biometryVerificationId: biomentryVerificationId,
                            biometryData: biometryData
                        ))
                    },
                    onSuccess: { response in
                        do {
                            let points = try response.encryptedShards.map {
                                let decryptedShard = try session.deviceKey.decrypt(data: $0.encryptedShard.data)
                                return Point(
                                    x: $0.participantId.bigInt,
                                    y: BigInt(sign: .plus, magnitude: BigUInt(decryptedShard))
                                    
                                )
                            }
                            
                            let intermediateKey = try EncryptionKey.generateFromPrivateKeyRaw(data: String(SecretSharerUtils.recoverSecret(shares: points), radix: 16).hexData()!)
                            let masterKey = try EncryptionKey.generateFromPrivateKeyRaw(data: try intermediateKey.decrypt(base64EncodedString: encryptedMasterKey))
                            self.status = .showingSecrets(
                                secrets: try requestedSecrets.map {
                                    RecoveredSecret(
                                        label: $0.label,
                                        secret: String(decoding: try masterKey.decrypt(base64EncodedString: $0.encryptedSeedPhrase), as: UTF8.self)
                                    )
                                }
                            )
                        } catch {
                            print("Failed to decrypt secrets: \(error)")
                            self.error = CensoError.failedToDecryptSecrets
                            self.showingError = true
                        }
                    }
                )
            case .showingSecrets(let secrets):
                List {
                    ForEach(secrets, id:\.label) { recoveredSecret in
                        VStack {
                            Text(recoveredSecret.label)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(recoveredSecret.secret)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
        .navigationTitle(Text("Your seed phrases"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                BackButton()
            }
        }
        .alert("Error", isPresented: $showingError, presenting: error) { _ in
            Button {
                dismiss()
            } label: { Text("OK") }
        } message: { error in
            Text(error.localizedDescription)
        }
        .onDisappear {
            deleteRecovery()
        }
    }
}

#if DEBUG
struct RecoveredSecretsView_Previews: PreviewProvider {
    static var previews: some View {
        LockedScreen(
            Session.sample,
            600,
            onOwnerStateUpdated: { _ in },
            onUnlockedTimeOut: {}
        ) {
            RecoveredSecretsView(
                session: .sample,
                requestedSecrets: [],
                encryptedMasterKey: Base64EncodedString(data: Data()),
                deleteRecovery: {},
                status: RecoveredSecretsView.Status.showingSecrets(
                    secrets: [
                        RecoveredSecretsView.RecoveredSecret(label: "Secret 1", secret: "Secret Phrase 1"),
                        RecoveredSecretsView.RecoveredSecret(label: "Secret 2", secret: "Secret Phrase 2"),
                    ]
                )
            )
        }
        
        LockedScreen(
            Session.sample,
            600,
            onOwnerStateUpdated: { _ in },
            onUnlockedTimeOut: {}
        ) {
            RecoveredSecretsView(
                session: .sample,
                requestedSecrets: [],
                encryptedMasterKey: Base64EncodedString(data: Data()),
                deleteRecovery: {},
                status: RecoveredSecretsView.Status.retrievingShards,
                showingError: true,
                error: CensoError.failedToDecryptSecrets
            )
        }
    }
}
#endif
