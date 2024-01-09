//
//  SettingsTab.swift
//
//  Created by Brendan Flood on 10/23/23.
//

import SwiftUI
import Moya

struct SettingsTab: View {
    @Environment(\.apiProvider) var apiProvider
    
    var session: Session
    var ownerState: API.OwnerState.Ready
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    
    @State private var showingError = false
    @State private var error: Error?
    @State private var resetRequested = false
    @State private var resetInProgress = false
    @State private var showApproversRemoval = false
    @State private var showPushNotificationSettings = false
    @AppStorage("pushNotificationsEnabled") var pushNotificationsEnabled: String?
    @ObservedObject var globalMaintenanceState = GlobalMaintenanceState.shared
    @State private var showAlert = false
    
    var body: some View {
        VStack {
            Text("Settings")
                .font(.largeTitle)
            Spacer()
            ScrollView {
                SettingsItem(title: "Lock App", buttonText: "Lock", description: "Lock the app so that it cannot be accessed without a face scan. This will prevent someone who has your phone from entering the Censo app.") {
                    lock()
                }

                let externalApprovers = ownerState.policy.approvers
                    .filter({ !$0.isOwner })
                
                if externalApprovers.count > 0 {
                    SettingsItem(title: "Remove Approvers", buttonText: "Remove", description: "Remove your approvers and return to yourself as the sole approval required for seed phrase access.  After doing this, you may optionally select new approvers to add.") {
                        showApproversRemoval = true
                    }
                }
                
                if resetInProgress {
                    ProgressView()
                } else {
                    SettingsItem(title: "Delete My Data", buttonText: "Delete", description: "This will securely delete all of your information stored in the Censo app.  After completing this, you will no longer have access to any seed phrases you have entered.  This operation cannot be undone.") {
                        resetRequested = true
                    }
                }
                
                if pushNotificationsEnabled != "true" {
                    SettingsItem(title: "Allow Push Notification", buttonText: "Enable", description: "Enable notifications to receive security and update alerts from Censo.") {
                        showPushNotificationSettings = true
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $showApproversRemoval, content: {
            InitApproversRemovalFlow(
                session: session,
                ownerState: ownerState,
                onOwnerStateUpdated: onOwnerStateUpdated
            )
        })
        .sheet(isPresented: $showPushNotificationSettings, content: {
            PushNotificationSettings {
                showPushNotificationSettings = false
            }
        })
        .onChange(of: showingError) { _ in updateAlertPresentation() }
        .onChange(of: globalMaintenanceState.isMaintenanceMode) { _ in updateAlertPresentation() }
        .alert("Error", isPresented: $showAlert, presenting: error) { _ in
            Button {
                showingError = false
                error = nil
            } label: { Text("OK") }
        } message: { error in
            Text(error.localizedDescription)
        }
        .alert("Delete Data", isPresented: $resetRequested) {
            Button {
                deleteUser()
            } label: { Text("Confirm") }
            Button {
            } label: { Text("Cancel") }
        } message: {
            Text("You are about to delete **ALL** of your data. Seed phrases you have added will no longer be accessible. This action cannot be reversed.\nAre you sure?")
        }
    }
    
    private func updateAlertPresentation() {
        // Update showAlert based on the combined condition
        showAlert = showingError && !globalMaintenanceState.isMaintenanceMode
    }
    
    private func deleteUser() {
        resetInProgress = true
        apiProvider.request(with: session, endpoint: .deleteUser) { result in
            resetInProgress = false
            switch result {
            case .success:
                if let ownerTrustedApprover = ownerState.policy.approvers.first(where: { $0.isOwner }) {
                    session.deleteApproverKey(participantId: ownerTrustedApprover.participantId)
                }
                if let ownerProspectApprover = ownerState.policySetup?.owner {
                    session.deleteApproverKey(participantId: ownerProspectApprover.participantId)
                }
                NotificationCenter.default.post(name: Notification.Name.deleteUserDataNotification, object: nil)
                pushNotificationsEnabled = nil
            case .failure(let error):
                self.showingError = true
                self.error = error
            }
        }
    }
    
    private func lock() {
        apiProvider.decodableRequest(with: session, endpoint: .lock) { (result: Result<API.LockApiResponse, MoyaError>) in
            switch result {
            case .success(let payload):
                onOwnerStateUpdated(payload.ownerState)
            case .failure(let err):
                error = err
                showingError = true
            }
        }
    }
}

#if DEBUG
#Preview {
    SettingsTab(session: .sample, 
                ownerState: API.OwnerState.Ready(policy: .sample2Approvers, vault: .sample, authType: .facetec, subscriptionStatus: .active),
                onOwnerStateUpdated: {_ in }
    )
}
#endif
