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
                }
                Button("Confirm", role: .destructive) {
                    if (deleteConfirmation == deleteConfirmationMessage()) {
                        deleteConfirmation = ""
                        onDelete()
                    } else {
                        incorrectConfirmation = true
                    }
                }
            } message: {
                Text("This action will delete **ALL** of your data. Seed phrases you have added will no longer be accessible. This action cannot be reversed.\nIf you are sure, please type:\n**\"\(deleteConfirmationMessage())\"**")
            }
            .alert("Confirmation does not match", isPresented: $incorrectConfirmation) {
                Button("Cancel", role: .cancel) {
                    deleteConfirmation = ""
                }
                Button("Retry", role: .destructive) {
                    deleteRequested = true
                }
            }
    }
    
    private func deleteConfirmationMessage() -> String {
        return "Delete my \(numSeedPhrases) seed phrase\(numSeedPhrases == 1 ? "" : "s")"
    }
}

extension View {
    func deleteAllDataAlert(title: String, numSeedPhrases: Int, deleteRequested: Binding<Bool>, onDelete: @escaping () -> Void) -> some View {
        modifier(DeleteAllDataAlert(title: title, numSeedPhrases: numSeedPhrases, deleteRequested: deleteRequested, onDelete: onDelete))
    }
    
}

#if DEBUG
#Preview {
    Text("Hello")
        .deleteAllDataAlert(
            title: "Delete Data",
            numSeedPhrases: 1,
            deleteRequested: .constant(true),
            onDelete: {}
        )
}
#endif