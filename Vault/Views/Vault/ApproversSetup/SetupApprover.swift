//
//  SetupApprover.swift
//  Vault
//
//  Created by Anton Onyshchenko on 24.10.23.
//

import Foundation
import SwiftUI
import Moya

struct SetupApprover : View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss
    
    var session: Session
    var policySetup: API.PolicySetup?
    var isPrimary: Bool
    var onComplete: () -> Void
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    
    @State private var inProgress = false
    @State private var showingError = false
    @State private var error: Error?
    
    var body: some View {
        if inProgress {
            ProgressView()
        } else {
            if let policySetup,
               let approver = isPrimary ? policySetup.primaryApprover : policySetup.backupApprover {
                ActivateApprover(
                    session: session,
                    approver: approver,
                    isPrimary: isPrimary,
                    onComplete: onComplete,
                    onOwnerStateUpdated: onOwnerStateUpdated
                )
            } else {
                EnterApproverNickname(
                    onSave: { setupPolicy(newApproverNickname: $0) }
                )
                .alert("Error", isPresented: $showingError, presenting: error) { _ in
                    Button {
                        showingError = false
                        error = nil
                    } label: {
                        Text("OK")
                    }
                } message: { error in
                    Text(error.localizedDescription)
                }
            }
        }
    }
    
    private func showError(_ error: Error) {
        inProgress = false

        self.error = error
        self.showingError = true
    }
    
    private func setupPolicy(newApproverNickname: String) {
        do {
            let guardians: [API.GuardianSetup]
            if let owner = policySetup?.guardians.first,
               let primaryApprover = policySetup?.guardians.last {
                guardians = [
                    .implicitlyOwner(API.GuardianSetup.ImplicitlyOwner(
                        participantId: owner.participantId,
                        label: "Me",
                        guardianPublicKey: try session.getOrCreateApproverKey(participantId: owner.participantId).publicExternalRepresentation()
                    )),
                    .externalApprover(API.GuardianSetup.ExternalApprover(
                        participantId: primaryApprover.participantId,
                        label: primaryApprover.label,
                        deviceEncryptedTotpSecret: try .encryptedTotpSecret(deviceKey: session.deviceKey)
                    )),
                    .externalApprover(API.GuardianSetup.ExternalApprover(
                        participantId: .random(),
                        label: newApproverNickname,
                        deviceEncryptedTotpSecret: try .encryptedTotpSecret(deviceKey: session.deviceKey)
                    ))
                ]
            } else {
                let participantId = ParticipantId.random()
                guardians = [
                    .implicitlyOwner(API.GuardianSetup.ImplicitlyOwner(
                        participantId: participantId,
                        label: "Me",
                        guardianPublicKey: try session.getOrCreateApproverKey(participantId: participantId).publicExternalRepresentation()
                    )),
                    .externalApprover(API.GuardianSetup.ExternalApprover(
                        participantId: .random(),
                        label: newApproverNickname,
                        deviceEncryptedTotpSecret: try .encryptedTotpSecret(deviceKey: session.deviceKey)
                    ))
                ]
            }
            
            self.inProgress = true
            
            apiProvider.decodableRequest(
                with: session,
                endpoint: .setupPolicy(API.SetupPolicyApiRequest(threshold: 2, guardians: guardians))
            ) { (result: Result<API.OwnerStateResponse, MoyaError>) in
                switch result {
                case .success(let response):
                    onOwnerStateUpdated(response.ownerState)
                    self.inProgress = false
                case .failure(let error):
                    showError(error)
                }
            }
        } catch {
            showError(error)
        }
    }
}
