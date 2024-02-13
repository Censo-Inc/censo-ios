//
//  PhrasesTab.swift
//
//  Created by Brendan Flood on 10/23/23.
//

import SwiftUI

struct PhrasesTab: View {
    @EnvironmentObject var ownerRepository: OwnerRepository
    @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController
    
    var ownerState: API.OwnerState.Ready
    
    @State private var showingError = false
    @State private var error: Error?
    @State private var showingEditSheet = false
    @State private var editingIndex: Int?
    @State private var phraseGuidsBeingDeleted: Set<String> = []
    @State private var showingDeleteConfirmation = false
    @State private var deleteConfirmationIndex = 0
    @State private var showingAddPhrase = false
    @State private var showingAccess: Bool = false
    @State private var confirmAccessCancelation: Bool = false
    @State private var deletingAccess: Bool = false
    @State private var deleteConfirmationText = ""
    @State private var showingDeleteNotConfirmed: Bool = false
    @State private var showingRenameSheet = false

    private func deleteConfirmationMessage(_ i: Int) -> String {
        return  "Delete \(ownerState.vault.seedPhrases[i].label)"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    ForEach(0..<ownerState.vault.seedPhrases.count, id: \.self) { i in
                        SeedPhrasePill(seedPhrase: ownerState.vault.seedPhrases[i], index: i, onEdit: {
                            showingEditSheet = true
                            editingIndex = i
                        })
                        .padding(.bottom)
                    }
                }
                .padding(.bottom)
                .listStyle(.plain)
                .scrollIndicators(ScrollIndicatorVisibility.hidden)
                .confirmationDialog("Edit", isPresented: $showingEditSheet, presenting: editingIndex) { i in
                    Button  {
                        showingEditSheet = false
                        showingRenameSheet = true
                    } label: {
                        Text("Rename")
                    }
                    
                    Button(role: .destructive) {
                        showingEditSheet = false
                        showingDeleteConfirmation = true
                        deleteConfirmationIndex = i
                    } label: {
                        Text("Delete")
                    }
                } message: { i in
                    Text(ownerState.vault.seedPhrases[i].label)
                }

                Divider()
                
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
                            Text("Cancel access")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(RoundedButtonStyle())
                    .disabled(deletingAccess)
                    .padding(.bottom)
                    .accessibilityIdentifier("cancelAccessButton")
                } else {
                    Button {
                        showingAccess = true
                    } label: {
                        Text(getAccessButtonLabel())
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(ownerState.vault.seedPhrases.isEmpty)
                    .buttonStyle(RoundedButtonStyle())
                    .padding(.vertical)
                    .accessibilityIdentifier("\(getAccessButtonLabel()) Button")
                }
                
                Button {
                    showingAddPhrase = true
                } label: {
                    Text("Add seed phrase")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle())
                .accessibilityIdentifier("addSeedPhraseButton")
                .padding(.bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .padding(.horizontal, 32)
            .sheet(isPresented: $showingAddPhrase, content: {
                AdditionalPhrase(ownerState: ownerState)
            })
            .sheet(isPresented: $showingAccess, content: {
                InitPhrasesAccessFlow(ownerState: ownerState)
            })
            .sheet(isPresented: $showingRenameSheet, content: {
                RenameSeedPhrase(
                    ownerState: ownerState,
                    editingIndex: editingIndex!,
                    onComplete: {
                        showingRenameSheet = false
                    }
                )
            })
            .alert("Cancel access", isPresented: $confirmAccessCancelation) {
                Button {
                    deleteAccess()
                } label: { Text("Confirm") }.accessibilityIdentifier("confirmCancelAccessButton")
                Button {
                } label: { Text("Cancel") }.accessibilityIdentifier("cancelCancelAccessButton")
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
            .alert("Delete Confirmation", isPresented: $showingDeleteConfirmation, presenting: deleteConfirmationIndex) { i in
                TextField(text: $deleteConfirmationText) {
                    Text(deleteConfirmationMessage(i))
                }
                .accessibilityIdentifier("deleteConfirmationTextField")
                Button("Cancel", role: .cancel) {
                    deleteConfirmationText = ""
                }
                .accessibilityIdentifier("cancelDeleteConfirmationButton")
                Button("Confirm", role: .destructive) {
                    if (deleteConfirmationText == deleteConfirmationMessage(i)) {
                        deletePhrase(ownerState.vault.seedPhrases[i])
                    } else {
                        showingDeleteNotConfirmed = true
                    }
                    deleteConfirmationText = ""
                }
                .accessibilityIdentifier("confirmDeleteConfirmationButton")
            } message: { i in
                Text("You are about to delete this phrase. If you are sure, type:\n\"\(deleteConfirmationMessage(i))\"")
            }
            .alert("Delete Confirmation", isPresented: $showingDeleteNotConfirmed) {
                Button("Ok") { }
            } message: {
                Text("Delete was not confirmed")
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
            return ownerState.policy.externalApproversCount > 0 ? "Request access" : "Begin access"
        }
        return "Show seed phrase\(ownerState.vault.seedPhrases.count > 1 ? "s" : "")"
    }
    
    func deletePhrase(_ seedPhrase: API.SeedPhrase) {
        phraseGuidsBeingDeleted.insert(seedPhrase.guid)
        ownerRepository.deleteSeedPhrase(seedPhrase.guid) { result in
            switch result {
            case .success(let payload):
                ownerStateStoreController.replace(payload.ownerState)
            case .failure(let error):
                showError(error)
            }
            phraseGuidsBeingDeleted.remove(seedPhrase.guid)
        }
    }
    
    private func deleteAccess(onSuccess: @escaping () -> Void = {}) {
        self.deletingAccess = true
        ownerRepository.deleteAccess { result in
            self.deletingAccess = false
            switch result {
            case .success(let response):
                ownerStateStoreController.replace(response.ownerState)
            case .failure(let error):
                self.showingError = true
                self.error = error
            }
        }
    }
    
    private func refreshState() {
        ownerStateStoreController.reload()
    }
    
    private func showError(_ error: Error) {
        self.error = error
        self.showingError = true
    }
}

#if DEBUG
#Preview {
    LoggedInOwnerPreviewContainer {
        PhrasesTab(
            ownerState: .sample
        )
    }
}
#endif
