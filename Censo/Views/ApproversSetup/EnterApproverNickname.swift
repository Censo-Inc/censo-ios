//
//  EnterApproverNickname.swift
//  Censo
//
//  Created by Anton Onyshchenko on 24.10.23.
//

import Foundation
import SwiftUI
import Moya
import Sentry

struct EnterApproverNickname: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss
    
    var session: Session
    var policySetup: API.PolicySetup?
    var isPrimary: Bool
    var onComplete: (API.OwnerState) -> Void
    var onBack: (() -> Void)?
    
    @StateObject private var nickname = ApproverNickname()
    @State private var submitting = false
    @State private var showingError = false
    @State private var error: Error?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            
            Text("Name your \(isPrimary ? "first" : "second") approver")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.bottom)
            
            Text("Give your approver a unique nickname so you can identify them.")
                .font(.subheadline)
                .padding(.bottom)

            VStack(spacing: 0) {
                TextField(text: $nickname.value) {
                    Text("Enter a nickname...")
                }
                .textFieldStyle(RoundedTextFieldStyle())
                .font(.title2)
                .frame(maxWidth: .infinity)
                
                Text(nickname.isTooLong ? "Can't be longer than \(nickname.limit) characters" : " ")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.red)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .padding(.bottom)
            
            Button {
                submit()
            } label: {
                Group {
                    if submitting {
                        ProgressView()
                    } else {
                        Text("Continue")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            .padding(.bottom)
            .disabled(submitting || !nickname.isValid)
        }
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
        .padding([.leading, .trailing], 32)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                if let onBack {
                    Button {
                        onBack()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                } else {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        })
    }
    
    private func showError(_ error: Error) {
        self.submitting = false
        self.error = error
        self.showingError = true
    }
    
    private func submit() {
        self.submitting = true
            
        do {
            let newApproverParticipantId = ParticipantId.random()
            let approvers: [API.ApproverSetup]
            
            if let owner = policySetup?.approvers.first,
               let primaryApprover = policySetup?.approvers.last {
                approvers = [
                    .implicitlyOwner(API.ApproverSetup.ImplicitlyOwner(
                        participantId: owner.participantId,
                        label: "Me",
                        approverPublicKey: try session.getOrCreateApproverKey(participantId: owner.participantId).publicExternalRepresentation()
                    )),
                    .externalApprover(API.ApproverSetup.ExternalApprover(
                        participantId: primaryApprover.participantId,
                        label: primaryApprover.label,
                        deviceEncryptedTotpSecret: try .encryptedTotpSecret(deviceKey: session.deviceKey)
                    )),
                    .externalApprover(API.ApproverSetup.ExternalApprover(
                        participantId: newApproverParticipantId,
                        label: nickname.value,
                        deviceEncryptedTotpSecret: try .encryptedTotpSecret(deviceKey: session.deviceKey)
                    ))
                ]
            } else {
                let ownerParticipantId = ParticipantId.random()
                approvers = [
                    .implicitlyOwner(API.ApproverSetup.ImplicitlyOwner(
                        participantId: ownerParticipantId,
                        label: "Me",
                        approverPublicKey: try session.getOrCreateApproverKey(participantId: ownerParticipantId).publicExternalRepresentation()
                    )),
                    .externalApprover(API.ApproverSetup.ExternalApprover(
                        participantId: newApproverParticipantId,
                        label: nickname.value,
                        deviceEncryptedTotpSecret: try .encryptedTotpSecret(deviceKey: session.deviceKey)
                    ))
                ]
            }
            
            apiProvider.decodableRequest(
                with: session,
                endpoint: .setupPolicy(API.SetupPolicyApiRequest(threshold: 2, approvers: approvers))
            ) { (result: Result<API.OwnerStateResponse, MoyaError>) in
                switch result {
                case .success(let response):
                    onComplete(response.ownerState)
                case .failure(let error):
                    showError(error)
                }
            }
        } catch {
            SentrySDK.captureWithTag(error: error, tagValue: "Setup policy")
            showError(CensoError.failedToSaveApproversName)
        }
    }
}

#if DEBUG
#Preview {
    NavigationView {
        ApproversSetup(
            session: .sample,
            ownerState: API.OwnerState.Ready(
                policy: .sample,
                vault: .sample,
                policySetup: nil,
                authType: .facetec,
                subscriptionStatus: .active,
                timelockSetting: .sample
            ),
            onOwnerStateUpdated: { _ in }
        )
        .foregroundColor(Color.Censo.primaryForeground)
    }
}
#endif
