//
//  PhrasesTab.swift
//
//  Created by Brendan Flood on 10/23/23.
//

import SwiftUI
import Moya

struct PhrasesTab: View {
    
    @Environment(\.apiProvider) var apiProvider
    
    var session: Session
    var ownerState: API.OwnerState.Ready
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    
    @State private var showingError = false
    @State private var error: Error?
    @State private var showingEditSheet = false
    @State private var editingIndex: Int?
    @State private var phraseGuidsBeingDeleted: Set<String> = []
    @State private var showingDeleteConfirmation = false
    @State private var showingAddPhrase = false
    @State private var showingAccess: Bool = false
    @State private var confirmAccessCancelation: Bool = false
    @State private var deletingAccess: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                ScrollView {
                    ForEach(0..<ownerState.vault.seedPhrases.count, id: \.self) { i in
                        ZStack(alignment: .leading) {
                            Button {
                                showingEditSheet = true
                                editingIndex = i
                            } label: {
                                HStack {
                                    Spacer()
                                    Image("Pencil")
                                        .renderingMode(.template).padding([.trailing], 4)
                                }
                            }
                            
                            Text(ownerState.vault.seedPhrases[i].label)
                                .font(.system(size: 18, weight: .medium))
                                .multilineTextAlignment(.leading)
                                .padding([.bottom, .leading, .top])
                                .padding([.trailing], 35)
                        }
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1))
                                .foregroundColor(.Censo.gray224)
                        )
                        .padding(.horizontal)
                        .padding(.top)
                    }
                }
                .confirmationDialog("Edit", isPresented: $showingEditSheet, presenting: editingIndex) { i in
                    Button(role: .destructive) {
                        showingEditSheet = false
                        showingDeleteConfirmation = true
                    } label: {
                        Text("Delete")
                    }
                } message: { i in
                    Text(ownerState.vault.seedPhrases[i].label)
                }
                .confirmationDialog(
                    Text("Are you sure?"),
                    isPresented: $showingDeleteConfirmation,
                    presenting: editingIndex
                ) { i in
                    Button("Yes", role: .destructive) {
                        deletePhrase(ownerState.vault.seedPhrases[i])
                    }
                } message: { i in
                    Text("You are about to delete \"\(ownerState.vault.seedPhrases[i].label)\".\n Are you sure?")
                }
                
                Divider().frame(maxWidth: .infinity)
                
                
                if let timelockExpiration = timelockExpiration() {
                    HStack {
                        Image("HourGlass")
                            .renderingMode(.template)
                        TimelockCountdown(
                            expiresAt: timelockExpiration,
                            onExpired: refreshState
                        )
                    }
                    .frame(height: 32)
                    .padding(.vertical)

                    Button(role: .destructive) {
                        confirmAccessCancelation = true
                    } label: {
                        HStack {
                            Text("Cancel Access")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                        }
                        .frame(maxWidth: 208)
                    }
                    .buttonStyle(RoundedButtonStyle())
                    .disabled(deletingAccess)
                    .padding([.horizontal, .bottom])
                } else {
                    Button {
                        showingAccess = true
                    } label: {
                        Text(getAccessButtonLabel())
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: 208)
                    }
                    .buttonStyle(RoundedButtonStyle())
                    .padding()
                }
                
                Button {
                    showingAddPhrase = true
                } label: {
                    Text("Add Seed Phrase")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: 208)
                }
                .buttonStyle(RoundedButtonStyle())
                
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Text("Seed Phrases"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .padding(.horizontal)
            .sheet(isPresented: $showingAddPhrase, content: {
                AdditionalPhrase(
                    ownerState: ownerState,
                    session: session,
                    onComplete: onOwnerStateUpdated
                )
            })
            .sheet(isPresented: $showingAccess, content: {
                InitPhrasesAccessFlow(
                    session: session,
                    ownerState: ownerState,
                    onOwnerStateUpdated: onOwnerStateUpdated
                )
            })
            .alert("Cancel access", isPresented: $confirmAccessCancelation) {
                Button {
                    deleteAccess()
                } label: { Text("Confirm") }
                Button {
                } label: { Text("Cancel") }
            } message: {
                Text("If you cancel access you will need to wait for the timelock period to access your phrases again. Are you sure?")
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
    }
    
    func timelockExpiration() -> Date? {
        guard case let .thisDevice(access) = ownerState.access,
              access.intent == .accessPhrases,
              access.status == .timelocked
        else {
            return nil
        }
        return access.unlocksAt
    }
    
    func getAccessButtonLabel() -> String {
        guard case let .thisDevice(access) = ownerState.access,
              access.intent == .accessPhrases,
              access.status == .available
        else {
            return ownerState.policy.externalApproversCount > 0 ? "Request Access" : "Begin Access"
        }
        return "Show Seed Phrase\(ownerState.vault.seedPhrases.count > 1 ? "s" : "")"
    }
    
    func deletePhrase(_ seedPhrase: API.SeedPhrase) {
        phraseGuidsBeingDeleted.insert(seedPhrase.guid)
        apiProvider.decodableRequest(with: session, endpoint: .deleteSeedPhrase(guid: seedPhrase.guid)) { (result: Result<API.DeleteSeedPhraseApiResponse, MoyaError>) in
            switch result {
            case .success(let payload):
                onOwnerStateUpdated(payload.ownerState)
            case .failure(let error):
                showError(error)
            }
            phraseGuidsBeingDeleted.remove(seedPhrase.guid)
        }
    }
    
    private func deleteAccess(onSuccess: @escaping () -> Void = {}) {
        self.deletingAccess = true
        apiProvider.decodableRequest(with: session, endpoint: .deleteAccess) { (result: Result<API.DeleteAccessApiResponse, MoyaError>) in
            self.deletingAccess = false
            switch result {
            case .success(let response):
                onOwnerStateUpdated(response.ownerState)
            case .failure(let error):
                self.showingError = true
                self.error = error
            }
        }
    }
    
    private func refreshState() {
        apiProvider.decodableRequest(with: session, endpoint: .user) { (result: Result<API.User, MoyaError>) in
            switch result {
            case .success(let user):
                onOwnerStateUpdated(user.ownerState)
            default:
                break
            }
        }
    }
    
    private func showError(_ error: Error) {
        self.error = error
        self.showingError = true
    }
}

#if DEBUG
#Preview {
    PhrasesTab(
        session: .sample,
        ownerState: API.OwnerState.Ready(policy: .sample, vault: .sample, authType: .facetec, subscriptionStatus: .active, timelockSetting: .sample),
        onOwnerStateUpdated: { _ in }
    )
    .foregroundColor(Color.Censo.primaryForeground)
}
#endif
