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
    @State private var timelockUpdateInProgress = false
    @State private var cancelDisableRequested = false
    @State private var showApproversRemoval = false
    @State private var showPushNotificationSettings = false
    @State private var deleteConfirmation = ""
    @State var timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    @AppStorage("pushNotificationsEnabled") var pushNotificationsEnabled: String?

    func deleteConfirmationMessage() -> String {
        return "Delete my \(ownerState.vault.seedPhrases.count) seed phrase\(ownerState.vault.seedPhrases.count == 1 ? "" : "s")"
    }

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
                        if ownerState.hasBlockingPhraseAccessRequest {
                            showError(CensoError.cannotRemoveApproversWhileAccessInProgress)
                        } else {
                            showApproversRemoval = true
                        }
                    }
                }
                
                if ownerState.timelockSetting.currentTimelockInSeconds == nil {
                    SettingsItem(title: "Enable Timelock", buttonText: "Enable", description: "Enabling the timelock adds additional safety when accessing seed phrases. After requesting access to seed phrases, you will need to wait for \(ownerState.timelockSetting.defaultTimelockInSeconds.toDisplayDuration()) before being able to view them.", buttonDisabled: timelockUpdateInProgress) {
                        enableOrDisableTimelock(enable: true)
                    }
                } else if let disabledAt = ownerState.timelockSetting.disabledAt {
                    SettingsItem(title: "Cancel Disable Timelock", buttonText: "Cancel", description: "Waiting \(disabledAt.toDisplayDuration()) before disabling the timelock. If you want to leave the timelock enabled, you can cancel now.", buttonDisabled: timelockUpdateInProgress) {
                        cancelDisableRequested = true
                        enableOrDisableTimelock(enable: false)
                    }
                    .onReceive(timer) { _ in
                        if (Date.now >= disabledAt) {
                            refreshState()
                        }
                    }
                } else {
                    SettingsItem(title: "Disable Timelock", buttonText: "Disable", description: "Timelock (\(ownerState.timelockSetting.currentTimelockInSeconds!.toDisplayDuration())) is enabled. You may initiate disabling the timelock but it will take \(ownerState.timelockSetting.currentTimelockInSeconds!.toDisplayDuration()) before the timelock is disabled", buttonDisabled: timelockUpdateInProgress) {
                        enableOrDisableTimelock(enable: false)
                    }
                }
                
                SettingsItem(title: "Delete My Data", buttonText: "Delete", description: "This will securely delete all of your information stored in the Censo app.  After completing this, you will no longer have access to any seed phrases you have entered.  This operation cannot be undone.", buttonDisabled: resetInProgress) {
                    resetRequested = true
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
        .dismissableAlert(
            isPresented: $showingError,
            error: $error,
            okAction: {
                showingError = false
                error = nil
            }
        )
        .alert("Delete Data Confirmation", isPresented: $resetRequested) {
            TextField(text: $deleteConfirmation) {
                Text(deleteConfirmationMessage())
            }
            Button("Cancel", role: .cancel) {
                deleteConfirmation = ""
            }
            Button("Confirm", role: .destructive) {
                if (deleteConfirmation == deleteConfirmationMessage()) {
                    deleteUser()
                }
                deleteConfirmation = ""
            }
        } message: {
            Text("You are about to delete **ALL** of your data. Seed phrases you have added will no longer be accessible. This action cannot be reversed.\nIf you are sure, please type:\n**\"\(deleteConfirmationMessage())\"**")
        }
        .alert("Cancel Disable Timelock", isPresented: $cancelDisableRequested) {
            Button {
                cancelDisableTimelock()
            } label: { Text("Confirm") }
            Button {
            } label: { Text("Cancel") }
        } message: {
            Text("This will cancel the pending request to disable the timelock\nAre you sure?")
        }
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
                showError(error)
            }
        }
    }
            
    private func enableOrDisableTimelock(enable: Bool) {
        timelockUpdateInProgress = true
        apiProvider.decodableRequest(with: session, endpoint: enable ? .enableTimelock : .disableTimelock) { (result: Result<API.TimelockApiResponse, MoyaError>) in
            timelockUpdateInProgress = false
            switch result {
            case .success(let payload):
                onOwnerStateUpdated(payload.ownerState)
            case .failure(let err):
                showError(err)
            }
        }
    }
    
    private func cancelDisableTimelock() {
        timelockUpdateInProgress = true
        apiProvider.request(with: session, endpoint: .cancelDisabledTimelock) { result in
            switch result {
            case .success:
                refreshState()
            case .failure(let err):
                timelockUpdateInProgress = false
                showError(err)
            }
        }
    }
    
    private func refreshState() {
        apiProvider.decodableRequest(with: session, endpoint: .user) { (result: Result<API.User, MoyaError>) in
            timelockUpdateInProgress = false
            switch result {
            case .success(let user):
                onOwnerStateUpdated(user.ownerState)
            default:
                break
            }
        }
    }
    
    private func lock() {
        apiProvider.decodableRequest(with: session, endpoint: .lock) { (result: Result<API.LockApiResponse, MoyaError>) in
            switch result {
            case .success(let payload):
                onOwnerStateUpdated(payload.ownerState)
            case .failure(let err):
                showError(err)
            }
        }
    }
    
    private func showError(_ error: Error) {
        self.error = error
        self.showingError = true
    }
}


#if DEBUG
#Preview("Enable Timelock") {
    SettingsTab(session: .sample,
                ownerState: API.OwnerState.Ready(policy: .sample2Approvers, vault: .sample, authType: .facetec, subscriptionStatus: .active, timelockSetting: .sample),
                onOwnerStateUpdated: {_ in }
    )
}

#Preview("Disable Timelock") {
    SettingsTab(session: .sample,
                ownerState: API.OwnerState.Ready(policy: .sample2Approvers, vault: .sample, authType: .facetec, subscriptionStatus: .active, timelockSetting: .sample2),
                onOwnerStateUpdated: {_ in }
    )
}

#Preview("Cancel Disable Timelock") {
    SettingsTab(session: .sample,
                ownerState: API.OwnerState.Ready(policy: .sample2Approvers, vault: .sample, authType: .facetec, subscriptionStatus: .active, timelockSetting: .sample3),
                onOwnerStateUpdated: {_ in }
    )
}
#endif
