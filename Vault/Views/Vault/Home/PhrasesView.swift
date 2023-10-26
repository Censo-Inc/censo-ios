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
    var ownerState: API.OwnerState.Ready
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    
    @State private var recoveryRequestInProgress = false
    @State private var showingError = false
    @State private var error: Error?
    @State private var showingEditSheet = false
    @State private var editingIndex: Int?
    @State private var secretsGuidsBeingDeleted: Set<String> = []
    @State private var showingDeleteConfirmation = false
    @State private var showingAddPhrase = false
    
    
    var body: some View {
        VStack {
            if let recovery = ownerState.recovery {
                if ownerState.policy.guardians.allSatisfy({ $0.isOwner }) {
                    NavigationView {
                        phraseHomeView()
                    }
                } else {
                    RecoveryView(
                        session: session,
                        threshold: ownerState.policy.threshold,
                        guardians: ownerState.policy.guardians,
                        encryptedSecrets: ownerState.vault.secrets,
                        encryptedMasterKey: ownerState.policy.encryptedMasterKey,
                        recovery: recovery,
                        onOwnerStateUpdated: onOwnerStateUpdated
                    )
                }
            } else {
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
                    NavigationView {
                        phraseHomeView()
                    }
                }
            }
        }
    }
    
    private func phraseHomeView() -> some View {
        VStack {
            HStack {
                Button {
                    showingAddPhrase = true
                } label: {
                    Text("Add")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: 188, maxHeight: 64)
                }
                .buttonStyle(RoundedButtonStyle())
                
                Spacer()
                
                Button {
                    requestRecovery()
                } label: {
                    HStack {
                        Image("LockLaminated")
                            .resizable()
                            .colorInvert()
                            .frame(width: 27, height: 24)
                        Text("Access")
                            .font(.system(size: 18, weight: .semibold))
                        
                    }
                    .frame(maxWidth: 188, maxHeight: 64)
                }
                .buttonStyle(RoundedButtonStyle())
            }
            .frame(maxWidth: .infinity, maxHeight: 64)
            .padding()
            
            Divider().frame(maxWidth: .infinity)
            
            GeometryReader { geometry in
                ScrollView {
                    ForEach(0..<ownerState.vault.secrets.count, id: \.self) { i in
                        ZStack(alignment: .leading) {
                            Button {
                                showingEditSheet = true
                                editingIndex = i
                            } label: {
                                HStack {
                                    Spacer()
                                    Image("Pencil").padding([.trailing], 4)
                                }
                            }
        
                            Text(ownerState.vault.secrets[i].label)
                                .font(.system(size: 18, weight: .medium))
                                .multilineTextAlignment(.leading)
                                .padding([.bottom, .leading, .top])
                                .padding([.trailing], 35)
                        }
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1))
                                .foregroundColor(.Censo.lightGray)
                        )
                        .padding()
                    }
                }
            }
        }
        .navigationTitle(Text("Seed Phrases"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .padding()
        .sheet(isPresented: $showingAddPhrase, content: {
            AdditionalPhrase(
                ownerState: ownerState,
                session: session,
                onComplete: onOwnerStateUpdated
            )
        })
        .confirmationDialog("Edit", isPresented: $showingEditSheet, presenting: editingIndex) { i in
            
            Button(role: .destructive) {
                showingEditSheet = false
                showingDeleteConfirmation = true
            } label: {
                Text("Delete")
            }
        } message: { i in
            Text(ownerState.vault.secrets[i].label)
        }
        .confirmationDialog(
            Text("Are you sure?"),
            isPresented: $showingDeleteConfirmation,
            presenting: editingIndex
        ) { i in
            Button("Yes", role: .destructive) {
                deleteSecret(ownerState.vault.secrets[i])
            }
        } message: { i in
            Text("You are about to delete \"\(ownerState.vault.secrets[i].label)\".\n Are you sure?")
        }
        .alert("Error", isPresented: $showingError, presenting: error) { _ in
            Button {
                showingError = false
                error = nil
            } label: { Text("OK") }
        } message: { error in
            Text(error.localizedDescription)
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
    
    func requestRecovery() {
        recoveryRequestInProgress = true
        apiProvider.decodableRequest(
            with: session,
            endpoint: .requestRecovery
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
    
    private func showError(_ error: Error) {
        self.error = error
        self.showingError = true
    }
}

#if DEBUG
#Preview {
    PhrasesView(
        session: .sample,
        ownerState: API.OwnerState.Ready(policy: .sample, vault: .sample),
        onOwnerStateUpdated: { _ in }
    )
}
#endif
