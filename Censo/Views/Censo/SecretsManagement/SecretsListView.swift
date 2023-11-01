//
//  SecretsListView.swift
//  Censo
//
//  Created by Anton Onyshchenko on 22.09.23.
//

import Foundation
import SwiftUI
import Moya

struct SecretsListView: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss
    
    var session: Session
    var vault: API.Vault
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    
    @State private var showingDeleteConfirmation = false
    @State private var secretToDelete: API.VaultSecret?
    @State private var secretsGuidsBeingDeleted: Set<String> = []
    @State private var showingError = false
    @State private var error: Error?
    @State private var showingAddPhrase = false

    var body: some View {
        VStack {
            List {
                ForEach(vault.secrets, id:\.guid) { secret in
                    if (!secretsGuidsBeingDeleted.contains(secret.guid)) {
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
                }
                .confirmationDialog(
                    Text("Are you sure?"),
                    isPresented: $showingDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Yes", role: .destructive) {
                        guard let secretToDelete else { return }
                        deleteSecret(secretToDelete)
                        self.secretToDelete = nil
                    }
                }
                .alert("Error", isPresented: $showingError, presenting: error) { _ in
                    Button { } label: { Text("OK") }
                } message: { error in
                    Text("Failed to delete phrase.\n\(error.localizedDescription)")
                }
                
            }
            
            Button {
                showingAddPhrase = true
            } label: {
                HStack {
                    Spacer()
                    Image(systemName: "plus")
                    Text(vault.secrets.isEmpty ? "Add a phrase" : "Add another")
                        .frame(height: 44)
                    Spacer()
                }.padding(1)
            }
            .padding()
            .buttonStyle(BorderedButtonStyle())
            
            Spacer()
        }
        .navigationTitle(Text("Your seed phrases"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                BackButton()
            }
        }
        .sheet(isPresented: $showingAddPhrase) {
            SeedEntry(
                session: session,
                publicMasterEncryptionKey: vault.publicMasterEncryptionKey,
                onSuccess: { newState in
                    showingAddPhrase = false
                    onOwnerStateUpdated(newState)
                }
            )
        }
    }
    
    func deleteSecret(_ secret: API.VaultSecret) {
        secretsGuidsBeingDeleted.insert(secret.guid)
        apiProvider.decodableRequest(with: session, endpoint: .deleteSecret(guid: secret.guid)) { (result: Result<API.DeleteSecretApiResponse, MoyaError>) in
            switch result {
            case .success(let payload):
                onOwnerStateUpdated(payload.ownerState)
            case .failure(let error):
                showError(error)
            }
            secretsGuidsBeingDeleted.remove(secret.guid)
        }
    }
    
    private func showError(_ error: Error) {
        self.error = error
        self.showingError = true
    }
}
