//
//  DeleteAllDataAlert.swift
//  Censo
//
//  Created by Brendan Flood on 1/25/24.
//

import SwiftUI

struct DeleteAllDataAlert: ViewModifier {
    var title: String
    var numSeedPhrases: Int
    @Binding var deleteRequested: Bool
    var onDelete: () -> Void
    
    @State private var deleteConfirmation = ""
    @State private var incorrectConfirmation = false
    
    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: $deleteRequested) {
                TextField(text: $deleteConfirmation) {
                    Text(deleteConfirmationMessage())
                }
                Button("Cancel", role: .cancel) {
                    deleteConfirmation = ""
                }.accessibilityIdentifier("cancelDeleteAllDataButton")
                Button("Confirm", role: .destructive) {
                    if (deleteConfirmation == deleteConfirmationMessage()) {
                        deleteConfirmation = ""
                        onDelete()
                    } else {
                        incorrectConfirmation = true
                    }
                }.accessibilityIdentifier("confirmDeleteAllDataButton")
            } message: {
                Text("This action will delete **ALL** of your data.\(numSeedPhrases > 0 ? " Seed phrases you have added will no longer be accessible." : "") This action cannot be reversed.\nIf you are sure, please type:\n**\"\(deleteConfirmationMessage())\"**")
            }
            .alert("Confirmation does not match", isPresented: $incorrectConfirmation) {
                Button("Cancel", role: .cancel) {
                    deleteConfirmation = ""
                }.accessibilityIdentifier("cancelConfirmationDoesNotMatchButton")
                Button("Retry", role: .destructive) {
                    deleteRequested = true
                }.accessibilityIdentifier("retryConfirmationDoesNotMatchButton")
            }
    }
    
    private func deleteConfirmationMessage() -> String {
        return numSeedPhrases > 0 ? "Delete my \(numSeedPhrases) seed phrase\(numSeedPhrases == 1 ? "" : "s")" : "Delete my data"
    }
}

extension View {
    func deleteAllDataAlert(title: String, ownerState: API.OwnerState, deleteRequested: Binding<Bool>, onDelete: @escaping () -> Void) -> some View {
        let numSeedPhrases: Int
        switch ownerState {
        case .ready(let ready):
            numSeedPhrases = ready.vault.seedPhrases.count
        default:
            numSeedPhrases = 0
        }
        
        return modifier(DeleteAllDataAlert(title: title, numSeedPhrases: numSeedPhrases, deleteRequested: deleteRequested, onDelete: onDelete))
    }
}

#if DEBUG
#Preview {
    Text("Hello")
        .deleteAllDataAlert(
            title: "Delete Data",
            ownerState: .ready(.sample),
            deleteRequested: .constant(true),
            onDelete: {}
        )
}
#endif
