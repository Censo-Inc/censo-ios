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
    
    var body: some View {
        VStack {
            Spacer()
            
            Button {
                lock()
            } label: {
                HStack {
                    Image(systemName: "lock")
                        .frame(maxWidth: 32, maxHeight: 32)
                    Text("Lock")
                        .font(.title2)
                }
                .frame(maxWidth: 322)
            }
            .buttonStyle(RoundedButtonStyle())
            .padding()
            
            let externalApprovers = ownerState.policy.approvers
                .filter({ !$0.isOwner })
            
            if externalApprovers.count > 0 {
                VStack(spacing: 5) {
                    Button {
                        showApproversRemoval = true
                    } label: {
                        HStack {
                            Spacer()
                            Image("TwoPeopleWhite")
                                .renderingMode(.template)
                                .resizable()
                                .frame(width: 32, height: 32)
                            Text(
                                "Remove approver\(externalApprovers.count > 1 ? "s" : "")"
                            )
                            .font(.title3)
                            Spacer()
                        }
                    }
                    .buttonStyle(RoundedButtonStyle())
                    
                    Text(
                        "An approval from current approver\(externalApprovers.count > 1 ? "s" : "") is required"
                    )
                    .font(.footnote)
                }
                .padding(.horizontal)
            }
            
            Button {
                resetRequested = true
            } label: {
                if resetInProgress {
                    ProgressView()
                } else {
                    HStack {
                        Image("arrow.circlepath")
                        Text("Delete Data")
                            .font(.title2)
                    }.frame(maxWidth: 322)
                }
            }
            .buttonStyle(RoundedButtonStyle())
            .padding()
            
            Spacer()
        }
        .sheet(isPresented: $showApproversRemoval, content: {
            InitApproversRemovalFlow(
                session: session,
                ownerState: ownerState,
                onOwnerStateUpdated: onOwnerStateUpdated
            )
        })
        .alert("Error", isPresented: $showingError, presenting: error) { _ in
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
                ownerState: API.OwnerState.Ready(policy: .sample, vault: .sample, authType: .facetec, subscriptionStatus: .active),
                onOwnerStateUpdated: {_ in }
    )
}
#endif
