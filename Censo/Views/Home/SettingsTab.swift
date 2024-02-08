//
//  SettingsTab.swift
//
//  Created by Brendan Flood on 10/23/23.
//

import SwiftUI
import Moya

struct SettingsTab: View {
    @EnvironmentObject var ownerRepository: OwnerRepository
    @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController
    
    var ownerState: API.OwnerState.Ready
    
    @State private var showingError = false
    @State private var error: Error?
    @State private var resetRequested = false
    @State private var resetInProgress = false
    @State private var timelockUpdateInProgress = false
    @State private var cancelDisableRequested = false
    @State private var showApproversRemoval = false
    @State private var showPushNotificationSettings = false
    
    @State var timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    @AppStorage("pushNotificationsEnabled") var pushNotificationsEnabled: String?

    func deleteConfirmationMessage() -> String {
        return "Delete my \(ownerState.vault.seedPhrases.count) seed phrase\(ownerState.vault.seedPhrases.count == 1 ? "" : "s")"
    }

    var body: some View {
        List {
            SettingsItem(title: "Lock app", buttonText: "Lock", buttonIdentifier: "lockButton", description: "Lock the app so that it cannot be accessed without a face scan. This will prevent someone who has your phone from entering the Censo app.") {
                lock()
            }
            
            let externalApprovers = ownerState.policy.approvers
                .filter({ !$0.isOwner })
            
            if externalApprovers.count > 0 {
                SettingsItem(title: "Remove approvers", buttonText: "Remove", description: "Remove your approvers and return to yourself as the sole approval required for seed phrase access.  After doing this, you may optionally select new approvers to add.") {
                    if ownerState.hasBlockingPhraseAccessRequest {
                        showError(CensoError.cannotRemoveApproversWhileAccessInProgress)
                    } else {
                        showApproversRemoval = true
                    }
                }
            }
            
            if ownerState.timelockSetting.currentTimelockInSeconds == nil {
                SettingsItem(title: "Enable timelock", buttonText: "Enable", buttonIdentifier: "enableTimelockButton", description: "Enabling the timelock adds additional safety when accessing seed phrases. After requesting access to seed phrases, you will need to wait for \(ownerState.timelockSetting.defaultTimelockInSeconds.toDisplayDuration()) before being able to view them.", buttonDisabled: timelockUpdateInProgress) {
                    enableOrDisableTimelock(enable: true)
                }
            } else if let disabledAt = ownerState.timelockSetting.disabledAt {
                SettingsItem(title: "Cancel disable timelock", buttonText: "Cancel", buttonIdentifier: "cancelDisableTimelockButton", description: "Waiting \(disabledAt.toDisplayDuration()) before disabling the timelock. If you want to leave the timelock enabled, you can cancel now.", buttonDisabled: timelockUpdateInProgress) {
                    cancelDisableRequested = true
                }
                .onReceive(timer) { _ in
                    if (Date.now >= disabledAt) {
                        refreshState()
                    }
                }
            } else {
                SettingsItem(title: "Disable timelock", buttonText: "Disable", buttonIdentifier: "disableTimelockButton", description: "Timelock (\(ownerState.timelockSetting.currentTimelockInSeconds!.toDisplayDuration())) is enabled. You may initiate disabling the timelock but it will take \(ownerState.timelockSetting.currentTimelockInSeconds!.toDisplayDuration()) before the timelock is disabled.", buttonDisabled: timelockUpdateInProgress) {
                    enableOrDisableTimelock(enable: false)
                }
            }
            
            SettingsItem(title: "Delete my data", buttonText: "Delete", buttonIdentifier: "deleteMyDataButton", description: "This will securely delete all of your information stored in the Censo app.  After completing this, you will no longer have access to any seed phrases you have entered.  This operation cannot be undone.", buttonDisabled: resetInProgress) {
                resetRequested = true
            }
            .listRowSeparator(pushNotificationsEnabled != "true" ? .visible : .hidden)
            
            if pushNotificationsEnabled != "true" {
                SettingsItem(title: "Allow push notifications", buttonText: "Enable", buttonIdentifier: "enablePushNotificaionButton", description: "Enable notifications to receive security and update alerts from Censo.") {
                    showPushNotificationSettings = true
                }
                .listRowSeparator(.hidden)
            }
        }
        .padding(.bottom)
        .listStyle(.plain)
        .scrollIndicators(ScrollIndicatorVisibility.hidden)
        .sheet(isPresented: $showApproversRemoval, content: {
            InitApproversRemovalFlow(ownerState: ownerState)
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
        .deleteAllDataAlert(
            title: "Delete Data Confirmation",
            numSeedPhrases: ownerState.vault.seedPhrases.count,
            deleteRequested: $resetRequested,
            onDelete: deleteUser
        )
        .alert("Cancel disable timelock", isPresented: $cancelDisableRequested) {
            Button {
                cancelDisableTimelock()
            } label: { Text("Confirm") }.accessibilityIdentifier("ConfirmCancelDisableTimelockButton")
            Button {
            } label: { Text("Cancel") }.accessibilityIdentifier("CancelCancelDisableTimelockButton")
                
        } message: {
            Text("This will cancel the pending request to disable the timelock\nAre you sure?")
        }
    }
    
    private func deleteUser() {
        resetInProgress = true
        deleteOwner(ownerRepository, .ready(ownerState), onSuccess: {
            resetInProgress = false
            pushNotificationsEnabled = nil
        }, onFailure: { error in
            resetInProgress = false
            showError(error)
        })
    }
            
    private func enableOrDisableTimelock(enable: Bool) {
        timelockUpdateInProgress = true
        ownerRepository.enableOrDisableTimelock(enable) { result in
            timelockUpdateInProgress = false
            switch result {
            case .success(let payload):
                ownerStateStoreController.replace(payload.ownerState)
            case .failure(let err):
                showError(err)
            }
        }
    }
    
    private func cancelDisableTimelock() {
        timelockUpdateInProgress = true
        ownerRepository.cancelDisabledTimelock { result in
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
        ownerRepository.getUser { result in
            timelockUpdateInProgress = false
            switch result {
            case .success(let user):
                ownerStateStoreController.replace(user.ownerState)
            default:
                break
            }
        }
    }
    
    private func lock() {
        ownerRepository.lock { result in
            switch result {
            case .success(let payload):
                ownerStateStoreController.replace(payload.ownerState)
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
    LoggedInOwnerPreviewContainer {
        SettingsTab(
            ownerState: API.OwnerState.Ready(
                policy: .sample2Approvers,
                vault: .sample,
                authType: .facetec,
                subscriptionStatus: .active,
                timelockSetting: .sample,
                subscriptionRequired: true,
                onboarded: true,
                canRequestAuthenticationReset: false
            )
        )
    }
}

#Preview("Disable Timelock") {
    LoggedInOwnerPreviewContainer {
        SettingsTab(
            ownerState: API.OwnerState.Ready(
                policy: .sample2Approvers,
                vault: .sample,
                authType: .facetec,
                subscriptionStatus: .active,
                timelockSetting: .sample2,
                subscriptionRequired: true,
                onboarded: true,
                canRequestAuthenticationReset: false
            )
        )
    }
}

#Preview("Cancel Disable Timelock") {
    LoggedInOwnerPreviewContainer {
        SettingsTab(
            ownerState: API.OwnerState.Ready(
                policy: .sample2Approvers,
                vault: .sample,
                authType: .facetec,
                subscriptionStatus: .active,
                timelockSetting: .sample3,
                subscriptionRequired: true,
                onboarded: true,
                canRequestAuthenticationReset: false
            )
        )
    }
}
#endif
