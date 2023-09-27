//
//  AddSecretView.swift
//  Vault
//
//  Created by Anton Onyshchenko on 27.09.23.
//

import Foundation
import SwiftUI
import Moya
import CryptoKit

struct AddSecretView: View {
    @Environment(\.apiProvider) var apiProvider
    
    var session: Session
    var publicMasterEncryptionKey: Base58EncodedPublicKey
    var onSuccess: () -> Void
    var onCancel: () -> Void
    
    @State private var secretLabel: String = ""
    @State private var secret: String = ""
    @State private var inProgress = false
    @State private var showingError = false
    @State private var error: Error?
    
    var body: some View {
        Section(header: Text("Add Secret").bold().foregroundColor(Color.black)) {
            Form {
                TextField("Enter Label", text: $secretLabel)
                    .font(.title3)
                
                TextField("Enter Secret", text: $secret)
                    .font(.title3)
                
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            storeSecret()
                        } label: {
                            if inProgress {
                                ProgressView()
                            } else {
                                Text("Add")
                            }
                        }
                        .buttonStyle(FilledButtonStyle())
                        .disabled(
                            inProgress ||
                            secretLabel.trimmingCharacters(in: .whitespaces).isEmpty ||
                            secret.trimmingCharacters(in: .whitespaces).isEmpty
                        )
                        
                        Spacer()
                    }
                    
                    HStack {
                        Spacer()
                        
                        Button("Cancel", role: .cancel) {
                            onCancel()
                        }
                        .padding()
                        .buttonStyle(BorderlessButtonStyle())
                        
                        Spacer()
                    }
                }
            }
        }
        .alert("Error", isPresented: $showingError, presenting: error) { _ in
            Button { } label: { Text("OK") }
        } message: { error in
            Text("Failed to store secret.\n\(error.localizedDescription)")
        }
    }
    
    private func storeSecret() {
        do {
            inProgress = true
            let secretData = secret.data(using: .utf8)!
            let encryptedSeedPhrase = try EncryptionKey
                .generateFromPublicExternalRepresentation(base58PublicKey: publicMasterEncryptionKey)
                .encrypt(data: secretData)
            
            let payload = API.StoreSecretApiRequest(
                encryptedSeedPhrase: encryptedSeedPhrase,
                seedPhraseHash: SHA256.hash(data: secretData).compactMap { String(format: "%02x", $0) }.joined(),
                label: secretLabel
            )
            apiProvider.decodableRequest(with: session, endpoint: .storeSecret(payload)) { (result: Result<API.StoreSecretApiResponse, MoyaError>) in
                switch result {
                case .success:
                    onSuccess()
                case .failure(let error):
                    showError(error)
                }
            }
        } catch {
            showError(error)
            return
        }
    }
    
    private func showError(_ error: Error) {
        inProgress = false
        self.error = error
        self.showingError = true
    }
}

