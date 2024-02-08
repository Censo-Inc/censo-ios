//
//  Settings.swift
//  Approver
//
//  Created by Anton Onyshchenko on 20.12.23.
//

import Foundation
import SwiftUI

struct Settings: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss
    var session: Session
    @Binding var user: API.ApproverUser
    
    @State var showOwners = false
    @State var showDeactivateAndDeleteConfirmation = false
    @State private var showingError = false
    @State private var error: Error?
    
    var body: some View {
        VStack {
            List {
                SettingsItem(title: "Who I'm helping", buttonText: "View", description: "View the people that you are an approver for.") {
                    showOwners = true
                }
                .listRowSeparator(.hidden)
                
                SettingsItem(title: "Delete data", buttonText: "Delete", description: "This will securely delete all of your information stored in the app.  After completing this, you will no longer be an approver.  This operation cannot be undone.") {
                    showDeactivateAndDeleteConfirmation = true
                }
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .scrollIndicators(ScrollIndicatorVisibility.hidden)
        }
        .padding(.horizontal)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationTitle("Settings")
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
        })
        .sheet(isPresented: $showOwners, content: {
            Owners(session: session, user: $user)
        })
        .alert("Delete Data", isPresented: $showDeactivateAndDeleteConfirmation) {
            Button {
                deleteApprover(apiProvider: apiProvider, session: session, onSuccess: {
                    self.showDeactivateAndDeleteConfirmation = false
                }, onFailure: { error in
                    self.showingError = true
                    self.error = error
                    self.showDeactivateAndDeleteConfirmation = false
                })
            } label: { Text("Confirm") }
            Button {
                showDeactivateAndDeleteConfirmation = false
            } label: { Text("Cancel") }
        } message: {
            Text("You are about to permanently delete your data and stop being an approver. THIS CANNOT BE UNDONE! The seed phrases you are helping to protect may become inaccessible if you confirm this action.\nAre you sure?")
        }
        .alert("Error", isPresented: $showingError, presenting: error) { _ in
            Button("OK", role: .cancel, action: {})
        } message: { error in
            Text(error.localizedDescription)
        }
    }
}

#if DEBUG
#Preview {
    @State var user = API.ApproverUser(approverStates: [
        .init(
            participantId: .random(),
            phase: .complete
        ),
        .init(
            participantId: .random(),
            phase: .complete
        )
    ])
    
    return NavigationStack {
        Settings(
            session: .sample,
            user: $user
        )
    }
    .foregroundColor(.Censo.primaryForeground)
}
#endif
