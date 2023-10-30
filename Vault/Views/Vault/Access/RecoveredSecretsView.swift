//
//  RecoveredPhrasesView.swift
//  Vault
//
//  Created by Anton Onyshchenko on 06.10.23.
//

import Foundation
import SwiftUI
import Moya
import raygun4apple

struct RecoveredSecretsView: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase
    
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
                VStack {
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
                                self.status = .showingSecrets(secrets: try recoverSecrets(response.encryptedShards))
                            } catch {
                                RaygunClient.sharedInstance().send(error: error, tags: ["Recovery"], customData: nil)
                                self.error = CensoError.failedToDecryptSecrets
                                self.showingError = true
                            }
                        },
                        onCancelled: {
                            dismiss()
                        }
                    )
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        BackButton()
                    }
                }
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
                
                Button {
                    dismissAndDeleteRecovery()
                } label: {
                    Text("Done Viewing")
                        .font(.system(size: 18))
                        .padding(.horizontal, 30)
                        .padding(.vertical, 5)
                        .foregroundColor(.white)
                }
                .buttonStyle(FilledButtonStyle(tint: .dark))
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                Text("Accessing phrases again will require another recovery")
                    .padding(.bottom, 20)
            }
        }
        .background(Color.white)
        .navigationTitle(Text("Your seed phrases"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .alert("Error", isPresented: $showingError, presenting: error) { _ in
            Button {
                dismiss()
            } label: { Text("OK") }
        } message: { error in
            Text(error.localizedDescription)
        }
        .onChange(of: scenePhase) { phase in
            // dismiss the view if if app goes to background or user switches to another app
            // this will allow them to access secrets without recovery, but will require a biometry
            if phase == .inactive || phase == .background {
                dismiss()
            }
        }
    }
    
    private func recoverSecrets(_ encryptedShards: [API.RetrieveRecoveryShardsApiResponse.EncryptedShard]) throws -> [RecoveredSecret] {
        let intermediateKey = try EncryptionKey.recover(encryptedShards, session)
        let masterKey = try EncryptionKey.fromEncryptedPrivateKey(encryptedMasterKey, intermediateKey)
        
        return try requestedSecrets.map {
            let decryptedSecret = try masterKey.decrypt(base64EncodedString: $0.encryptedSeedPhrase)
            let decodedWords = try BIP39.binaryDataToWords(binaryData: decryptedSecret)
            return RecoveredSecret(
                label: $0.label,
                secret: decodedWords.joined(separator: " ")
            )
        }
    }
    
    private func dismissAndDeleteRecovery() {
        dismiss()
        deleteRecovery()
    }
}

#if DEBUG
struct RecoveredSecretsView_Previews: PreviewProvider {
    static var previews: some View {
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
#endif
