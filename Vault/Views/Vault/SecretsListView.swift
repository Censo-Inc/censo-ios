//
//  VaultScreen.swift
//  Vault
//
//  Created by Anton Onyshchenko on 22.09.23.
//

import Foundation
import SwiftUI
import Moya

struct SecretsListView: View {
    @Environment(\.apiProvider) var apiProvider
    
    var session: Session
    var unlockedForSeconds: UInt?
    var vault: API.Vault
    var refreshOwnerState: () -> Void
    
    @State private var showingAdd = false
    @State private var showingDeleteConfirmation = false
    @State private var secretToDelete: API.VaultSecret?
    @State private var showingError = false
    @State private var error: Error?
    
    var body: some View {
        VStack {
            LockUnlockWrapper(session, unlockedForSeconds, refreshOwnerState) {
                if showingAdd {
                    AddSecretView(
                        session: session,
                        publicMasterEncryptionKey: vault.publicMasterEncryptionKey,
                        onSuccess: {
                            showingAdd = false
                            refreshOwnerState()
                        },
                        onCancel: { showingAdd = false }
                    )
                } else {
                    Section(header: Text("Secrets").bold().foregroundColor(Color.black)) {
                        List {
                            ForEach(vault.secrets, id:\.guid) { secret in
                                VStack {
                                    Text(secret.label)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.bottom, 1)
                                    Text("Created at \(secret.createdAt.formatted())")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .font(Font.footnote)
                                        .foregroundStyle(.gray)
                                }
                                .padding(1)
                                .swipeActions(edge: .trailing) {
                                    Button() {
                                        secretToDelete = secret
                                        showingDeleteConfirmation = true
                                    } label: {
                                        Text("Delete")
                                    }.tint(Color.red)
                                }
                            }
                            .confirmationDialog(
                                Text("Are you sure?"),
                                isPresented: $showingDeleteConfirmation,
                                titleVisibility: .visible
                            ) {
                                Button("Yes", role: .destructive) {
                                    withAnimation {
                                        guard let secretToDelete else { return }
                                        deleteSecret(secretToDelete)
                                        self.secretToDelete = nil
                                    }
                                }
                            }
                            .alert("Error", isPresented: $showingError, presenting: error) { _ in
                                Button { } label: { Text("OK") }
                            } message: { error in
                                Text("Failed to delete secret.\n\(error.localizedDescription)")
                            }
                            
                            Button {
                                showingAdd = true
                            } label: {
                                HStack {
                                    Spacer()
                                    Image(systemName: "plus")
                                    Text(vault.secrets.isEmpty ? "Add a secret" : "Add another")
                                    Spacer()
                                }.padding(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
            }
        }
    }
    
    func deleteSecret(_ secret: API.VaultSecret) {
        apiProvider.decodableRequest(with: session, endpoint: .deleteSecret(guid: secret.guid)) { (result: Result<API.DeleteSecretApiResponse, MoyaError>) in
            switch result {
            case .success:
                refreshOwnerState()
            case .failure(let error):
                showError(error)
            }
        }
    }
    
    private func showError(_ error: Error) {
        self.error = error
        self.showingError = true
    }
}
